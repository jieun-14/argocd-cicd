# dev-mgmt-cluster
dev 환경 mgmt k8s cluster 배포를 위한 argocd 연동용 repo 입니다

.  
├── README.md    
├── clusters  
│   ├── workload-cluster  
│   │   └── base  
│   │       ├── deployment.yaml  
│   │       ├── kustomization.yaml  
│   │       └── namespace.yaml  
│   └── workload-cluster-02  
│       ├── base  
│       │   ├── 1_cluster.yaml  
│       │   ├── 2_byocluster.yaml  
│       │   ├── 3_kubeadmcontrolplane.yaml  
│       │   ├── 4_byomachinetemplate.yaml  
│       │   ├── 5_kubeadmconfigtemplate.yaml  
│       │   ├── 6_machinedeployment.yaml  
│       │   ├── 7_byomachinetemplate_worker.yaml  
│       │   └── kustomization.yaml  
│       └── overlays  
│           └── in-dev  
│               ├── env-configmap.yaml  
│               └── kustomization.yaml  
└── test  
    └── infrastructure-provider-byoh  
        ├── byoh-agent-install.sh  
        ├── byoh-install.sh  
        ├── manifests  
        │   ├── 1_cluster.yaml  
        │   ├── 2_byocluster.yaml  
        │   ├── 3_kubeadmcontrolplane.yaml  
        │   ├── 4_byomachinetemplate.yaml  
        │   ├── 5_kubeadmconfigtemplate.yaml  
        │   ├── 6_machinedeployment.yaml  
        │   └── 7_byomachinetemplate_worker.yaml  
        └── ssh-provision.sh  
          
  
    
[byoh-install.sh]
이 스크립트는 BYOH(Bring Your Own Host) 환경의 호스트에 BYOH 구성 요소를 설치하는 데 사용됩니다.   

환경 설정 준비:
BYOH 호스트에서 필요한 기본 환경을 설정합니다(예: 패키지 업데이트 및 필수 의존성 설치).  

BYOH 관련 파일 다운로드 및 설치:
BYOH 에이전트 바이너리 또는 기타 관련 파일을 다운로드하고 설치 경로에 배치합니다.  

서비스 및 데몬 구성:
BYOH 에이전트를 서비스 형태로 실행하도록 구성하거나 데몬 프로세스를 설정합니다.  

작업 로그 출력:
설치 과정 및 상태 정보를 출력하여 디버깅에 도움을 줍니다.  
  
[byoh-agent-install.sh]
스크립트는 Cluster API의 Bring Your Own Host (BYOH) 환경에서 BYOH 에이전트를 설치하는 데 사용됩니다.   

필수 패키지 설치:
스크립트는 BYOH 에이전트가 동작하기 위해 필요한 의존성 패키지 및 도구를 설치합니다.  

BYOH 에이전트 바이너리 다운로드:
BYOH 에이전트 실행 파일을 지정된 위치에서 다운로드하거나 빌드하여 설정합니다.    

설정 및 구성:
에이전트가 호스트에서 올바르게 동작하도록 필요한 구성 파일이나 환경 설정을 적용합니다.  

서비스 실행:
BYOH 에이전트를 데몬이나 서비스로 실행하여 클러스터와 통신할 준비를 합니다.  
  
[ssh-provision.sh]
이 스크립트는 SSH를 통해 BYOH 노드를 프로비저닝하는 데 사용됩니다.   

SSH 연결 설정:
대상 호스트에 SSH로 접속하여 필요한 작업을 원격으로 실행할 준비를 합니다.  

필요한 명령 실행:
BYOH 에이전트를 설치하거나 설정하는 명령을 SSH를 통해 원격으로 실행합니다.  

파일 전송:
BYOH 에이전트 설치 스크립트나 기타 의존성을 SSH를 통해 원격 호스트에 복사합니다.  

자동화된 프로비저닝:
사전에 정의된 설정을 사용하여 여러 노드의 프로비저닝을 자동으로 처리할 수 있습니다.  
