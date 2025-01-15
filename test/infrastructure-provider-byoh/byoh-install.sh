#!/bin/bash
## OS
export CRI_VERSION='1.7.25-1'
export K8S_VERSION='1.30.8-1.1'
export APT_KEY_PATH='/usr/share/keyrings'
export APT_KEY_K8S='v1.30'

## BYOH
export APISERVER=$(kubectl config view -ojsonpath='{.clusters[0].cluster.server}')
export CA_CERT=$(kubectl config view --flatten -ojsonpath='{.clusters[0].cluster.certificate-authority-data}')
export CLIENT_CERT=$(kubectl config view --flatten -ojsonpath='{.users[0].user.client-certificate-data}')
export CLIENT_KEY=$(kubectl config view --flatten -ojsonpath='{.users[0].user.client-key-data}')
export CLUSTER_NAME=cicd-cluster
export NAMESPACE=cicd-test
export CONTROL_PLANE_ENDPOINT_IP="172.25.30.185"
export CONTROL_PLANE_ENDPOINT_PORT="6443"
export CONTROL_PLANE_MACHINE_COUNT="3"
export KUBERNETES_VERSION="v1.30.8"
export CONTROL_PLANE_ROLE="k8scont"
export OPENSTACK_NODE_ROLE="oscontrl"
export NETWORK_NODE_ROLE="osnetwk"
export COMPUTE_NODE_ROLE="oscompt"
export ENVIRONMENT="dev"
export WORKER_MACHINE_COUNT="2"

## CNI
export CNI=kube-ovn


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
)

if [[ "$ACTION" == "install" ]]; then
  for FILE in "${FILES[@]}"; do
    echo "Applying $FILE..."
    envsubst < "manifests/$FILE" | kubectl apply -f -
  done
elif [[ "$ACTION" == "delete" ]]; then
  for FILE in $(echo "${FILES[@]}" | tac); do
    echo "Deleting $FILE..."
    envsubst < "manifests/$FILE" | kubectl delete -f -
  done
fi
