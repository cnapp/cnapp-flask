#!/usr/bin/env bash

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

NO_COLOR="\033[0m"
OK_COLOR="\033[32;01m"
INFO_COLOR="\033[34;01m"
ERROR_COLOR="\033[31;01m"
WARN_COLOR="\033[33;01m"

CLUSTER_CONFIG="./deploy/k8s-kube-config"
MINIKUBE_CONFIG="./deploy/minikube-kube-config"
kubeconfig=""

clusters="minikube"
environments="local"

# Minikube cluster
minikube_url="minikube"

namespace=""

function check_argument {
        arg=$1
        msg=$2
        if [ -z "${arg}" ]; then
                echo -e "${ERROR_COLOR}Invalid data. ${msg}.${NO_COLOR}"
        usage
        exit 1
        fi
}

function kubectl_install {
    if [ ! -x "$(command -v minikube)" ]; then
        echo -e "${OK_COLOR}Downloading kubectl${NO_COLOR}"
        local kube_download="https://storage.googleapis.com/kubernetes-release/release"
        curl -LO ${kube_download}/$(curl -s ${kube_download}/stable.txt)/bin/linux/amd64/kubectl > ./kubectl
        chmod +x ./kubectl
        export PATH=${PATH}:.
        kubectl version --client
    fi
}

function minikube_install {
    if [ ! -x "$(command -v minikube)" ]; then
        echo -e "${OK_COLOR}Downloading minikube${NO_COLOR}"
        curl -Lo minikube ${MINIKUBE_URI}/releases/latest/minikube-linux-amd64 \
            && chmod +x minikube
        export PATH=${PATH}:.
    fi
}

function kube_config {
    env=$1
    case ${env} in
        local)
            kubeconfig=${MINIKUBE_CONFIG}
            ;;
        stg|dev|itg|prp|prod)
            kubeconfig=${CLUSTER_CONFIG}
            ;;
        *)
            echo -e "${ERROR_COLOR}Invalid environment: ${env}${NO_COLOR}"
            exit 1
    esac
    echo -e "${INFO_COLOR}Use config: ${kubeconfig}${NO_COLOR}"
}


function kube_context {
    if  [ ! -x "$(command -v kubectl)" ]; then
        kubectl_install
    fi
    echo -e "${INFO_COLOR}Cluster: $1"
    echo -e "${INFO_COLOR}Environment: $2"
    if [ "local" = "$2" ]; then
        local context="cnapps"
        namespace="-n cnapps"
        echo -e "${INFO_COLOR}Namespace: ${namespace}"
    else
        local context="${1}-cnapps-$2"
    fi
    kube_config ${env}
    echo -e "${OK_COLOR}Switch to Kubernetes context: ${context}${NO_COLOR}" >&2
    kubectl --kubeconfig=${kubeconfig} config use-context ${context} >&2 || exit 1
}
