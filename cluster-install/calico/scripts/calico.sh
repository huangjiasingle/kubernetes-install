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

## Create etcd.conf, etcd.service, and start etcd service.


ETCD_SERVERS=${1:-"http://8.8.8.18:4001"}

HOST_IP=`hostname -i`
HOST_NAME=`hostname`

sed -i '$a\export ETCD_ENDPOINTS='"${ETCD_SERVERS}"'' /etc/profile
source /etc/profile


cat <<EOF >/etc/cni/net.d/10-calico.conf
{
"name" : "calico-k8s-network",
"type" : "calico",
"etcd_endpoints" : "${ETCD_SERVERS}",
"log_level" : "debug",
"ipam" : {
"type" : "calico-ipam"
    }
}
EOF

cat <<EOF >/usr/lib/systemd/system/calico-node.service
[Unit]
Description=calicoctl node
After=docker.service
Requires=docker.service
[Service]
User=root
Environment=ETCD_ENDPOINTS=${ETCD_SERVERS}
PermissionsStartOnly=true
ExecStart=/usr/bin/calicoctl node --ip=${HOST_IP} --detach=false
Restart=always
RestartSec=10
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable calico-node
systemctl start calico-node
