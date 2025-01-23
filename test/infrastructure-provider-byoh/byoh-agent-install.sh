#!/bin/bash

## Pre-configuration
sudo -i
apt-get install socat ebtables ethtool conntrack
#ROLE_NAME=$(echo "$HOSTNAME" | awk -F'-' '{print gensub(/[0-9]+$/, "", "g", $3)}')
ROLE_NAME=$(echo "$HOSTNAME" | awk -F'-' '{print $2}' | sed 's/[0-9]*//g')
NAMESPACE="next-test"
ENVIRONMENT="dev"

## Add a hostname to localhost IP
HOST_ENTRY="127.0.0.1 $HOSTNAME"
grep -qxF "$HOST_ENTRY" /etc/hosts || echo "$HOST_ENTRY" >> /etc/hosts

## Agent Download
#wget https://github.com/vmware-tanzu/cluster-api-provider-bringyourownhost/releases/download/v0.5.0/byoh-hostagent-linux-amd64
curl -L -o byoh-hostagent-linux-amd64 "https://github.com/vmware-tanzu/cluster-api-provider-bringyourownhost/releases/download/v0.5.0/byoh-hostagent-linux-amd64"
mv byoh-hostagent-linux-amd64 /usr/local/bin/byoh-agent
chmod +x /usr/local/bin/byoh-agent

## Register byoh-agent with systemd
## /etc/systemd/system/byoh-agent.service
cat << EOF > /etc/systemd/system/byoh-agent.service
[Unit]
Description=byoh-agent service
After=network.target
[Service]
Type=simple
Environment="NS_ARGS=--namespace $NAMESPACE"
Environment="CERT_ARGS=--certExpiryDuration 189216000"
Environment="CERTIFICATE_ROTATION=true"
Environment="METRIC_ARGS=--metricsbindaddress :10001"
Environment="LABEL_ARGS=--label environment=$ENVIRONMENT --label role=$ROLE_NAME --label hostname=$HOSTNAME"
Environment="MGMT_ARGS=--bootstrap-kubeconfig /etc/byoh-agent/mgmt/kubeconfig"
Environment="INSTALL_ARGS=--skip-installation true"
ExecStart=/usr/local/bin/byoh-agent \$NS_ARGS \$CERT_ARGS \$LABEL_ARGS \$MGMT_ARGS \$INSTALL_ARGS \$METRIC_ARGS
Restart=always
User=root
Group=root
[Install]
WantedBy=multi-user.target
EOF

## Register byoh-agent-watch with systemd
## /etc/systemd/system/byoh-agent-watch.service
cat << EOF > /etc/systemd/system/byoh-agent-watch.service
[Unit]
Description=byoh-agent restarter
After=network.target
[Service]
Type=oneshot
ExecStart=/usr/bin/systemctl restart byoh-agent.service
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable byoh-agent
systemctl restart byoh-agent
