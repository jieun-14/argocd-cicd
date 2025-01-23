#!/bin/bash

# 원격 서버 목록
PEM_KEY="/root/k2ptest.pem"
REMOTE_IPS=("xxx.xxx.xxx.xxx" "xxx.xxx.xxx.xxx" "xxx.xxx.xxx.xxx" "xxx.xxx.xxx.xxx" "xxx.xxx.xxx.xxx")

# 계정을 자동으로 추가하여 원격 서버 주소 생성
USERNAME="ubuntu"
REMOTE_SERVERS=("${REMOTE_IPS[@]/#/$USERNAME@}")

# 로컬 파일 경로
LOCAL_ADMIN_FILE="/etc/kubernetes/admin.conf"
LOCAL_KUBECONFIG_FILE="./kubeconfig"
LOCAL_INSTALL_SCRIPT="./byoh-agent-install.sh"

# 원격 파일 저장 경로
REMOTE_FILES_DIR="/tmp"
TARGET_DIR="/etc/byoh-agent/mgmt"
TARGET_FILE="kubeconfig"

# 현재 경로에 kubeconfig 파일이 있는지 확인
if [ -f "$LOCAL_KUBECONFIG_FILE" ]; then
    echo "$LOCAL_KUBECONFIG_FILE 파일이 이미 현재 경로에 존재합니다."
else
    # /etc/kubernetes/admin.conf 파일이 존재하는지 확인
    if [ -f "$LOCAL_ADMIN_FILE" ]; then
        # 파일 복사
        cp "$LOCAL_ADMIN_FILE" "$TARGET_FILE"
        echo "$LOCAL_ADMIN_FILE 파일을 $TARGET_FILE 이름으로 복사했습니다."
    else
        echo "$LOCAL_ADMIN_FILE 파일이 존재하지 않습니다. 작업을 중단합니다."
        exit 1
    fi
fi

# 파일 존재 확인
if [ ! -f "$LOCAL_INSTALL_SCRIPT" ]; then
  echo "로컬에 필요한 파일이 없습니다. $LOCAL_INSTALL_SCRIPT를 확인하세요."
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
