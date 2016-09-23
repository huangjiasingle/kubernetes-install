#!/bin/bash

# Copyright 2015 The Kubernetes Authors All rights reserved.
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


# exit on any error
set -e

SSH_OPTS="-oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oLogLevel=ERROR"

# Use the config file specified in $CALICO_CONFIG_FILE, or default to
# config-default.sh.
CALICO_ROOT=$(dirname "${BASH_SOURCE}")/..
readonly ROOT=$(dirname "${BASH_SOURCE}")
source "${ROOT}/${CALICO_CONFIG_FILE:-"config-default.sh"}"

# Directory to be used for calico provisioning.
CALICO_TEMP="~/calico_temp"

CALICO_CNI_DIR="/opt/cni/bin/"


# Must ensure that the following ENV vars are set
function detect-node() {
  CALICO_NODE_IP_ADDRESSES=()
  for node in ${NODES}; do
    CALICO_NODE_IP_ADDRESSES+=("${node#*@}")
  done
  echo "CALICO_NODE_IP_ADDRESSES: [${CALICO_NODE_IP_ADDRESSES[*]}]" 1>&2
}

# Install handler for signal trap
function trap-add {
  local handler="$1"
  local signal="${2-EXIT}"
  local cur

  cur="$(eval "sh -c 'echo \$3' -- $(trap -p ${signal})")"
  if [[ -n "${cur}" ]]; then
    handler="${cur}; ${handler}"
  fi

  trap "${handler}" ${signal}
}

# Validate calico
function validate-cluster() {
  set +e
  for node in ${NODES}; do
    troubleshoot-node $node
  done
  set -e
}

# Instantiate calico
function calico-up() {

  for node in ${NODES}; do
    provision-node $node 
  done

  detect-node

  validate-cluster
}

# Delete calico
function calico-down() {
  for node in ${NODES}; do
    tear-down-node $node
  done
}

function troubleshoot-node() {
  # Troubleshooting on node if all required daemons are active.
  echo "[INFO] Troubleshooting on node ${1}"
  local -a required_daemon=("calico-node")
  local daemon
  local daemon_status
  printf "%-24s %-10s \n" "PROCESS" "STATUS"
  for daemon in "${required_daemon[@]}"; do
    local rc=0
    calico-ssh "${1}" "sudo systemctl is-active ${daemon}" >/dev/null 2>&1 || rc="$?"
    if [[ "${rc}" -ne "0" ]]; then
      daemon_status="inactive"
    else
      daemon_status="active"
    fi
    printf "%-24s %s\n" ${daemon} ${daemon_status}
  done
  printf "\n"
}

function tear-down-node() {
  echo "[INFO] tear-down-node on ${1}"
  service_file="/usr/lib/systemd/system/calico-node.service"
  calico-ssh "${1}" " \
      if [[ -f $service_file ]]; then \
          sudo systemctl stop calico-node; \
          sudo systemctl disable calico-node; \
          sudo rm -f $service_file; \
      fi"
  calico-ssh "${1}" "sudo rm -rf /usr/bin/calico*"
  calico-ssh "${1}" "sudo rm -rf /opt/cni/bin/calico*"
  calico-ssh "${1}" "sudo rm -rf /etc/cni/"
  calico-ssh "${1}" "sudo rm -rf ${CALICO_TEMP}"
}

# Provision node
#
# Assumed vars:
#   NODE
#   CALICO_TEMP
function provision-node() {
  echo "[INFO] Provision node on ${1}"
  local node=${1}
  local node_ip=${node#*@}

  ensure-setup-dir ${node}

  calico-scp ${node} "${ROOT}/bin ${ROOT}/image ${ROOT}/scripts/ ${ROOT}/config-default.sh ${ROOT}/util.sh" ${CALICO_TEMP}
  calico-ssh "${node}" " \
    sudo chmod -R +x ${CALICO_TEMP}/bin/;  \
    sudo cp -r ${CALICO_TEMP}/bin/calicoctl /usr/bin/; \
    sudo cp -r ${CALICO_TEMP}/bin/calico ${CALICO_TEMP}/bin/calico-ipam ${CALICO_CNI_DIR}; \
    sudo docker load < ${CALICO_TEMP}/image/calico.tar; \
    sudo bash ${CALICO_TEMP}/scripts/calico.sh ${ETCD_SERVERS} "
}

# Create dirs that'll be used during setup on target machine.
#
# Assumed vars:
#   CALICO_TEMP
function ensure-setup-dir() {
  calico-ssh "${1}" "mkdir -p ${CALICO_TEMP}; \
                   mkdir -p /etc/cni/net.d/; \
                   mkdir -p ${CALICO_CNI_DIR}"
}

# Run command over ssh
function calico-ssh() {
  local host="$1"
  shift
  ssh ${SSH_OPTS} -t "${host}" "$@" >/dev/null 2>&1
}

# Copy file recursively over ssh
function calico-scp() {
  local host="$1"
  local src=($2)
  local dst="$3"
  scp -r ${SSH_OPTS} ${src[*]} "${host}:${dst}"
}

