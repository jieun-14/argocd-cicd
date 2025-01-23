#!/bin/bash
## OS
export CRI_VERSION='1.7.25-1'
export K8S_VERSION='1.30.8-1.1'
export APT_KEY_PATH='/usr/share/keyrings'
export APT_KEY_K8S="v${K8S_VERSION%.*.*}"

## BYOH
export CLUSTER_NAME="byoh-cluster"
export NAMESPACE="next-test"
export CONTROL_PLANE_ENDPOINT_IP="172.25.30.185"
export CONTROL_PLANE_ENDPOINT_PORT="6443"
export CONTROL_PLANE_MACHINE_COUNT="3"
export KUBERNETES_VERSION="v${K8S_VERSION%-*}"
#export CONTROL_PLANE_ROLE="k8scont"
export CONTROL_PLANE_ROLE="master"
export OPENSTACK_NODE_ROLE="oscontrl"
export NETWORK_NODE_ROLE="osnetwk"
#export COMPUTE_NODE_ROLE="oscompt"
export COMPUTE_NODE_ROLE="worker"
export ENVIRONMENT="dev"
export WORKER_MACHINE_COUNT="2"

## CNI
export CNI_NAME="kube-ovn"
export CNI_LABEL="kube-ovn"
export OVN_DB_IPS="172.25.30.146,172.25.30.108,172.25.30.132"


## 실행
ACTION=$1

# 사용법 출력
usage() {
  echo "Usage: $0 [install|delete]"
  exit 1
}

# 파라미터 확인
if [[ $# -ne 1 ]]; then
  usage
fi

if [[ "$ACTION" != "install" && "$ACTION" != "delete" ]]; then
  usage
fi

# 파일 리스트
FILES=(
  "1_cluster.yaml"
  "2_byocluster.yaml"
  "3_kubeadmcontrolplane.yaml"
  "4_byomachinetemplate.yaml"
  "5_kubeadmconfigtemplate.yaml"
  "6_machinedeployment.yaml"
  "7_byomachinetemplate_worker.yaml"
  "cni_kubeovn-configmap.yaml"
  "cni_clusterresourceset.yaml"
)

if [[ "$ACTION" == "install" ]]; then
  for FILE in "${FILES[@]}"; do
    echo "Applying $FILE..."
    envsubst < "byoh/$FILE" | kubectl apply -f -
  done
elif [[ "$ACTION" == "delete" ]]; then
  for FILE in $(printf "%s\n" "${FILES[@]}" | tac); do
    echo "Deleting $FILE..."
    envsubst < "byoh/$FILE" | kubectl delete -f -
  done
fi
