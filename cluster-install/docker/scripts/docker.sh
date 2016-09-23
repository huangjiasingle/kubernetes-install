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

## Create docker.conf, docker.service, and start docker service.


REGISTRY_SERVER_IP_ADDRESS=${1:-"http://8.8.8.18:4001"}
STORAGE_DEVICE_NAME=${2:-"/dev/mapper/centos-root"}
DATA_SIZE=${3:-"100G"}

cat <<EOF >/etc/docker/docker
# /etc/sysconfig/docker

# Modify these options if you want to change the way the docker daemon runs
OPTIONS='--selinux-enabled -H tcp://0.0.0.0:4243 -api-enable-cors -H unix:///var/run/docker.sock'

DOCKER_CERT_PATH=/etc/docker

# If you want to add your own registry to be used for docker search and docker
# pull use the ADD_REGISTRY option to list a set of registries, each prepended
# with --add-registry flag. The first registry added will be the first registry
# searched.
#ADD_REGISTRY='--add-registry '

# If you want to block registries from being used, uncomment the BLOCK_REGISTRY
# option and give it a set of registries, each prepended with --block-registry
# flag. For example adding docker.io will stop users from downloading images
# from docker.io
# BLOCK_REGISTRY='--block-registry'

# If you have a registry secured with https but do not have proper certs
# distributed, you can tell docker to not look for full authorization by
# adding the registry to the INSECURE_REGISTRY line and uncommenting it.
# INSECURE_REGISTRY='--insecure-registry'
INSECURE_REGISTRY='--insecure-registry $REGISTRY_SERVER_IP_ADDRESS'
# On an SELinux system, if you remove the --selinux-enabled option, you
# also need to turn on the docker_transition_unconfined boolean.
# setsebool -P docker_transition_unconfined 1

# Location used for temporary files, such as those created by
# docker load and build operations. Default is /var/lib/docker/tmp
# Can be overriden by setting the following environment variable.
# DOCKER_TMPDIR=/var/tmp

# Controls the /etc/cron.daily/docker-logrotate cron job status.
# To disable, uncomment the line below.
# LOGROTATE=false
EOF

cat <<EOF >/etc/docker/docker-network
# /etc/sysconfig/docker-network
DOCKER_NETWORK_OPTIONS=
EOF

cat <<EOF >/etc/docker/docker-storage
DOCKER_STORAGE_OPTIONS=""
EOF

cat <<EOF >/etc/docker/docker-storage-setup
# Edit this file to override any configuration options specified in
# /usr/lib/docker-storage-setup/docker-storage-setup.
#
# For more details refer to "man docker-storage-setup"
DEVS=${STORAGE_DEVICE_NAME}
DATA_SIZE=${DATA_SIZE}
EOF

cat <<EOF >/usr/lib/systemd/system/docker.service
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.com
After=network.target
Wants=docker-storage-setup.service

[Service]
Type=notify
NotifyAccess=all
EnvironmentFile=-/etc/docker/docker
EnvironmentFile=-/etc/docker/docker-storage
EnvironmentFile=-/etc/docker/docker-network
Environment=GOTRACEBACK=crash
ExecStart=/bin/sh -c '/usr/bin/docker daemon \$OPTIONS \\
          \$DOCKER_STORAGE_OPTIONS \\
          \$DOCKER_NETWORK_OPTIONS \\
          \$ADD_REGISTRY \\
          \$BLOCK_REGISTRY \\
          \$INSECURE_REGISTRY \\
          2>&1 | /usr/bin/forward-journald -tag docker'
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity
MountFlags=slave
TimeoutStartSec=0
Restart=on-failure
StandardOutput=null
StandardError=null

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF >/usr/lib/systemd/system/docker-storage-setup.service
[Unit]
Description=Docker Storage Setup
After=cloud-final.service
Before=docker.service

[Service]
Type=oneshot
ExecStart=/usr/bin/docker-storage-setup
EnvironmentFile=-/etc/docker/docker-storage-setup

[Install]
WantedBy=multi-user.target
EOF



systemctl daemon-reload
systemctl enable docker
systemctl start docker
