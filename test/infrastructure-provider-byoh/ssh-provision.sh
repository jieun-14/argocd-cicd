#!/bin/bash

# 원격 서버 목록
#PEM_KEY="/root/k2ptest.pem"
REMOTE_IPS=("172.25.30.146" "172.25.30.108" "172.25.30.132" "172.25.30.74" "172.25.30.167")

# 계정을 자동으로 추가하여 원격 서버 주소 생성
USERNAME="root"
REMOTE_SERVERS=("${REMOTE_IPS[@]/#/$USERNAME@}")

# 로컬 파일 경로
LOCAL_KUBECONFIG_FILE="./bootstrap-kubeconfig.conf"
LOCAL_INSTALL_SCRIPT="./byoh-agent-install.sh"

# 원격 파일 저장 경로
REMOTE_FILES_DIR="/tmp"
TARGET_DIR="/etc/byoh-agent/mgmt"
TARGET_FILE="kubeconfig"

# bootstrapkubeconfig
#kubectl delete bootstrapkubeconfigs.infrastructure.cluster.x-k8s.io -n test bootstrap-kubeconfig
NAME="bootstrap-kubeconfig"
NAMESPACE="cicd-test"
APISERVER=$(kubectl config view -ojsonpath='{.clusters[0].cluster.server}')
CA_CERT=$(kubectl config view --flatten -ojsonpath='{.clusters[0].cluster.certificate-authority-data}')

# workload cluster 자원을 구분할 management cluster namespace 생성
kubectl create namespace $NAMESPACE

# BootstrapKubeconfig 상태 확인
EXISTING_AGE=$(kubectl get bootstrapkubeconfig $NAME -n $NAMESPACE -o=jsonpath='{.metadata.creationTimestamp}' 2>/dev/null | \
               xargs -I{} date -d {} +%s 2>/dev/null)
CURRENT_TIME=$(date +%s)

if [[ -n "$EXISTING_AGE" ]]; then
  # 생성 후 경과 시간 계산 (초 단위)
  AGE=$((CURRENT_TIME - EXISTING_AGE))

  if [[ $AGE -lt 1800 ]]; then
    echo "BootstrapKubeconfig 생성 후 30분 이내입니다. 기존 리소스를 사용합니다."
    # 기존 데이터 가져오기
    BOOT_FILE=$(kubectl get bootstrapkubeconfig $NAME -n $NAMESPACE -o=jsonpath='{.status.bootstrapKubeconfigData}')
    echo "$BOOT_FILE" > bootstrap-kubeconfig.conf
    echo "기존 BootstrapKubeconfig 데이터를 저장했습니다."
  else
    echo "BootstrapKubeconfig 생성 후 30분이 지나 기존 리소스를 삭제합니다."
    kubectl delete bootstrapkubeconfig $NAME -n $NAMESPACE
  fi
else
  echo "기존 BootstrapKubeconfig 리소스가 존재하지 않습니다. 새로 생성합니다."
fi

# bootstrapkubeconfig 생성
cat <<EOF | kubectl apply -f -
apiVersion: infrastructure.cluster.x-k8s.io/v1beta1
kind: BootstrapKubeconfig
metadata:
  name: "$NAME"
  namespace: "$NAMESPACE"
spec:
  apiserver: "$APISERVER"
  certificate-authority-data: "$CA_CERT"
EOF
sleep 2
BOOT_FILE=$(kubectl get bootstrapkubeconfig $NAME -n $NAMESPACE -o=jsonpath='{.status.bootstrapKubeconfigData}') 
echo "$BOOT_FILE" > bootstrap-kubeconfig.conf

# 파일 존재 확인
if [ ! -f "$LOCAL_KUBECONFIG_FILE" ] || [ ! -f "$LOCAL_INSTALL_SCRIPT" ]; then
  echo "로컬에 필요한 파일이 없습니다. $LOCAL_KUBECONFIG_FILE 또는 $LOCAL_INSTALL_SCRIPT를 확인하세요."
  exit 1
fi

# 모든 원격 서버에서 작업 수행
for REMOTE_SERVER in "${REMOTE_SERVERS[@]}"; do
  echo "==== $REMOTE_SERVER 에 파일 전송 및 작업 시작 ===="

  # 1. 파일 전송
  scp -i "$PEM_KEY" "$LOCAL_KUBECONFIG_FILE" "$REMOTE_SERVER:$REMOTE_FILES_DIR/" && \
  scp -i "$PEM_KEY" "$LOCAL_INSTALL_SCRIPT" "$REMOTE_SERVER:$REMOTE_FILES_DIR/"
  if [ $? -ne 0 ]; then
    echo "==== $REMOTE_SERVER 파일 전송 중 오류 발생 ===="
    continue
  fi

  # 2. SSH를 통해 작업 수행
  ssh -i "$PEM_KEY" "$REMOTE_SERVER" bash <<EOF
  # 2-1 /etc/byoh-agent/mgmt 디렉토리 생성
  sudo mkdir -p "$TARGET_DIR"

  # 2-2 bootstrap-kubeconfig.conf 파일 권한 변경 및 이동
  sudo mv "$REMOTE_FILES_DIR/$(basename "$LOCAL_KUBECONFIG_FILE")" "$TARGET_DIR/$TARGET_FILE"
  sudo chown root:root "$TARGET_DIR/$(basename "$TARGET_FILE")"
  echo "$(basename "$TARGET_FILE") 파일 이동 및 권한 변경 완료."

  # 2-3 byoh-agent-install.sh 파일 권한 변경 및 실행
#  sudo chown root:root "$REMOTE_FILES_DIR/$(basename "$LOCAL_INSTALL_SCRIPT")"
  sudo bash "$REMOTE_FILES_DIR/$(basename "$LOCAL_INSTALL_SCRIPT")"
  echo "$(basename "$LOCAL_INSTALL_SCRIPT") 파일 실행 완료."
EOF

  if [ $? -eq 0 ]; then
    echo "==== $REMOTE_SERVER 작업 완료 ===="
  else
    echo "==== $REMOTE_SERVER 작업 중 오류 발생 ===="
  fi
done
