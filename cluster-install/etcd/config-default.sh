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

## Contains configuration values for the CentOS cluster
# The user should have sudo privilege
export NODES=${NODES:-"root@192.168.1.150 root@192.168.1.151 root@192.168.1.152"}

export ETCD_INITIAL_CLUSTER="master=http://192.168.1.150:2380,minion1=http://192.168.1.151:2380,minion2=http://192.168.1.152:2380"

export CLUSTER_TOKEN=test-cluster
