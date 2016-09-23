#!/bin/bash

# Copyright 2014 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


MASTER_ADDRESS=${1:-"8.8.8.18"}
NODE_ADDRESS=${2:-"8.8.8.20"}
KUBELET_POD_INFRA_CONTAINER=${3:-"registry.access.redhat.com/rhel7/pod-infrastructure:latest"}

HOST_NAME=`hostname`

cat <<EOF >/etc/kubernetes/kubelet
# --logtostderr=true: log to standard error instead of files
KUBE_LOGTOSTDERR="--logtostderr=true"

#  --v=0: log level for V logs
KUBE_LOG_LEVEL="--v=4"

# --address=0.0.0.0: The IP address for the Kubelet to serve on (set to 0.0.0.0 for all interfaces)
NODE_ADDRESS="--address=0.0.0.0"

# --port=10250: The port for the Kubelet to serve on. Note that "kubectl logs" will not work if you set this flag.
NODE_PORT="--port=10250"

# --hostname-override="": If non-empty, will use this string as identification instead of the actual hostname.
NODE_HOSTNAME="--hostname-override=${HOST_NAME}"

# --api-servers=[]: List of Kubernetes API servers for publishing events, 
# and reading pods and services. (ip:port), comma separated.
KUBELET_API_SERVER="--api-servers=${MASTER_ADDRESS}"

# pod infrastructure container
KUBELET_POD_INFRA_CONTAINER="--pod-infra-container-image=$KUBELET_POD_INFRA_CONTAINER"

# --allow-privileged=false: If true, allow containers to request privileged mode. [default=false]
KUBE_ALLOW_PRIV="--allow-privileged=true"

# Add your own!
KUBELET_ARGS=""
EOF

KUBE_PROXY_OPTS="   \${KUBE_LOGTOSTDERR}     \\
                    \${KUBE_LOG_LEVEL}       \\
                    \${NODE_ADDRESS}         \\
                    \${NODE_PORT}            \\
                    \${NODE_HOSTNAME}        \\
                    \${KUBELET_API_SERVER}   \\
                    \${KUBELET_POD_INFRA_CONTAINER} \\
                    \${KUBE_ALLOW_PRIV}      \\
                    \${KUBELET_ARGS}"

cat <<EOF >/usr/lib/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
After=docker.service
Requires=docker.service

[Service]
EnvironmentFile=-/etc/kubernetes/kubelet
ExecStart=/usr/bin/kubelet --network-plugin-dir=/etc/cni/net.d --network-plugin=cni --cluster-dns=10.254.0.3 --cluster-domain=cluster.local \\
           ${KUBE_PROXY_OPTS}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kubelet
systemctl start kubelet
