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

# Use the config file specified in $ETCD_CONFIG_FILE, or default to
# config-default.sh.
ETCD_ROOT=$(dirname "${BASH_SOURCE}")/..
readonly ROOT=$(dirname "${BASH_SOURCE}")
source "${ROOT}/${ETCD_CONFIG_FILE:-"config-default.sh"}"

# Directory to be used for etcd provisioning.
ETCD_TEMP="~/etcd_temp"


# Must ensure that the following ENV vars are set
function detect-node() {
  ETCD_NODE_IP_ADDRESSES=()
  for node in ${NODES}; do
    ETCD_NODE_IP_ADDRESSES+=("${node#*@}")
  done
  echo "ETCD_NODE_IP_ADDRESSES: [${ETCD_NODE_IP_ADDRESSES[*]}]" 1>&2
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

# Validate a etcd cluster
function validate-cluster() {
  set +e
  for node in ${NODES}; do
    troubleshoot-node $node
  done
  set -e
}

# Instantiate etcd cluster
function etcd-up() {

  for node in ${NODES}; do
    provision-node $node 
  done

  detect-node

  validate-cluster
}

# Delete a etcd
function etcd-down() {
  for node in ${NODES}; do
    tear-down-node $node
  done
}

function troubleshoot-node() {
  # Troubleshooting on node if all required daemons are active.
  echo "[INFO] Troubleshooting on node ${1}"
  local -a required_daemon=("etcd")
  local daemon
  local daemon_status
  printf "%-24s %-10s \n" "PROCESS" "STATUS"
  for daemon in "${required_daemon[@]}"; do
    local rc=0
    etcd-ssh "${1}" "sudo systemctl is-active ${daemon}" >/dev/null 2>&1 || rc="$?"
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
  service_file="/usr/lib/systemd/system/etcd.service"
  etcd-ssh "${1}" " \
      if [[ -f $service_file ]]; then \
          sudo systemctl stop etcd; \
          sudo systemctl disable etcd; \
          sudo rm -f $service_file; \
      fi"
  etcd-ssh "${1}" "sudo rm -rf /etc/etcd/"
  etcd-ssh "${1}" "sudo rm -rf /usr/bin/etcd*"
  etcd-ssh "${1}" "sudo rm -rf ${ETCD_TEMP}"
  etcd-ssh "${1}" "sudo rm -rf /var/lib/etcd/default.etcd"
}

# Provision node
#
# Assumed vars:
#   NODE
#   ETCD_TEMP
function provision-node() {
  echo "[INFO] Provision node on ${1}"
  local node=${1}
  local node_ip=${node#*@}

  ensure-setup-dir ${node}

  etcd-scp ${node} "${ROOT}/bin ${ROOT}/scripts/ ${ROOT}/config-default.sh ${ROOT}/util.sh" ${ETCD_TEMP}
  etcd-ssh "${node}" " \
    sudo chmod -R +x ${ETCD_TEMP}/bin/;  \
    sudo cp -r ${ETCD_TEMP}/bin/* /usr/bin/; \
    sudo bash ${ETCD_TEMP}/scripts/etcd.sh ${CLUSTER_TOKEN} ${ETCD_INITIAL_CLUSTER}"
}

# Create dirs that'll be used during setup on target machine.
#
# Assumed vars:
#   KUBE_TEMP
function ensure-setup-dir() {
  etcd-ssh "${1}" "mkdir -p ${ETCD_TEMP}; \
                   sudo mkdir -p /etc/etcd/"
}

# Run command over ssh
function etcd-ssh() {
  local host="$1"
  shift
  ssh ${SSH_OPTS} -t "${host}" "$@" >/dev/null 2>&1
}

# Copy file recursively over ssh
function etcd-scp() {
  local host="$1"
  local src=($2)
  local dst="$3"
  scp -r ${SSH_OPTS} ${src[*]} "${host}:${dst}"
}

