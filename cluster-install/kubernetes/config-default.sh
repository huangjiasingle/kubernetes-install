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

# Define all your master nodes,
# And separated with blank space like <user_1@ip_1> <user_2@ip_2> <user_3@ip_3>.
# The user should have sudo privilege
export MASTERS=${MASTER:-"root@192.168.1.150 root@192.168.1.151 root@192.168.1.152"}

# Define all your minion nodes,
# And separated with blank space like <user_1@ip_1> <user_2@ip_2> <user_3@ip_3>.
# The user should have sudo privilege
export NODES=${NODES:-"root@192.168.1.150 root@192.168.1.151 root@192.168.1.152"}

# Number of nodes in your cluster.
export NUM_NODES=${NUM_NODES:-3}

# Should be removed when NUM_NODES is deprecated in validate-cluster.sh
export NUM_NODES=${NUM_NODES}

# By default, the cluster will use the etcd installed on master.
export ETCD_SERVERS=${ETCD_SERVERS:-"http://192.168.1.150:2379,http://192.168.1.151:2379,http://192.168.1.152:2379"}

# define the IP range used for service cluster IPs.
# according to rfc 1918 ref: https://tools.ietf.org/html/rfc1918 choose a private ip range here.
export SERVICE_CLUSTER_IP_RANGE=${SERVICE_CLUSTER_IP_RANGE:-"10.254.0.0/16"}

# Admission Controllers to invoke prior to persisting objects in cluster
export ADMISSION_CONTROL=NamespaceLifecycle,NamespaceExists,LimitRanger,ServiceAccount,ResourceQuota,SecurityContextDeny

# Timeouts for process checking on master and minion
export PROCESS_CHECK_TIMEOUT=${PROCESS_CHECK_TIMEOUT:-180} # seconds.

# The loadbalance ip address used to connect to apiserver
export LOADBALANCE_IP_ADDRESS=${LOADBALANCE_IP_ADDRESS:-"http://192.168.1.150:8080"}

# The infra image to use
export KUBELET_POD_INFRA_CONTAINER=${KUBELET_POD_INFRA_CONTAINER:-"reg.skycloud.com:5000/rhel7/pod-infrastructure"}
