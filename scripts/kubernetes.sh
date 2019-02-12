#!/usr/bin/env bash

# Copyright (C) 2018-2019 Nicolas Lamirault <nicolas.lamirault@gmail.com>

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

SCRIPT=$(readlink -f "$0")
# echo $SCRIPT
SCRIPTPATH=$(dirname "$SCRIPT")
# echo $SCRIPTPATH

. ${SCRIPTPATH}/commons.sh

app="cnapps-"

url=""

# Minikube cluster
minikube_url="minikube"


function usage {
    echo -e "${OK_COLOR}Usage:${NO_COLOR}"
    echo -e "$(basename $0) [options]${NO_COLOR}"
    echo -e ""
    echo -e "  -h         show list of command-line options ${NO_COLOR}"
    echo -e "  -c         cluster to use"
    echo -e "  -e         environment (local, dev, prod, ...)"
    echo -e "  -p         perform an action"
    echo -e "  -a         name of the application to deploy"
    echo -e "  -d         directory which contains Kubernetes definitions files"
    echo -e "  -i         tag of the Docker image to use"
    echo -e ""
    echo -e "${INFO_COLOR}Clusters${NO_COLOR} : ${clusters}"
    echo -e "${INFO_COLOR}Environments${NO_COLOR} : ${environments}"
    echo -e "${INFO_COLOR}Action${NO_COLOR} : create, destroy"
}


function kube_replace {
    app=$1
    image_tag=$2
    build_number=$3
    dir=$4
    tmpdir=$5
    echo -e "${OK_COLOR}Generate Kubernetes files for: ${app} ${dir}${NO_COLOR}"
    echo -e "Environment: ${env}"
    echo -e "Namespace: ${ns}"
    echo -e "App: ${app}"
    echo -e "Docker ${image_name}:${image_tag}"
    echo -e "Build: ${build_number}"
    echo -e "Output: ${tmpdir}"
    rm -fr ${tmpdir} && mkdir -p ${tmpdir} && cp -r ${dir}/* ${tmpdir}
    find ${tmpdir} -name "*.yaml" | xargs sed -i "s/__KUBE_APP__/${app}/g"
    find ${tmpdir} -name "*.yaml" | xargs sed -i "s/__KUBE_COMMIT_ID__/${build_number}/g"
    if [ "local" = "${env}" ]; then
        find ${tmpdir} -name "*.yaml" | xargs sed -i "s#__CI_REGISTRY_IMAGE__#${app}#g"
        find ${tmpdir} -name "*.yaml" | xargs sed -i "s#__CI_REGISTRY_TAG__#${image_tag}#g"
        find ${tmpdir} -name "*.yaml" | xargs sed -i "s#__KUBE_IMAGE_POLICY__#Never#g"
        find ${tmpdir} -name "*.yaml" | xargs sed -i "s#__KUBE_NAME__#minikube#g"
    else
        find ${tmpdir} -name "*.yaml" | xargs sed -i "s#__CI_REGISTRY_IMAGE__#${private_registry}/${image_name}#g"
        find ${tmpdir} -name "*.yaml" | xargs sed -i "s#__CI_REGISTRY_TAG__#${image_tag}#g"
        find ${tmpdir} -name "*.yaml" | xargs sed -i "s#__KUBE_IMAGE_POLICY__#Always#g"
        find ${tmpdir} -name "*.yaml" | xargs sed -i "s#__KUBE_NAME__#cloud#g"
    fi
}


function kube_directory {
    action=$1
    directory=$2
    if [ -d "${directory}" ]; then
        if [ -n "$(ls -A ${directory})" ]; then
            kubectl --kubeconfig=${kubeconfig} ${action} -f "${directory}" ${namespace}
        fi
    else
        echo -e "${INFO_COLOR}Skip ${directory}. Does not exists${NO_COLOR}"
    fi
}


function kube_files {
    action=$1
    directory=$2
    env=$3
    for file in $(ls ${directory}/*-${env}.yaml 2>/dev/null); do
        kubectl --kubeconfig=${kubeconfig} ${action} -f "${file}" ${namespace}
    done
}


function kube_deploy {
    dir=$1
    echo -e "${OK_COLOR}Current context: $(kubectl --kubeconfig=${kubeconfig} config current-context)${NO_COLOR}"
    kube_directory "apply" "${dir}/commons"
    kube_directory "apply" "${dir}/${cluster}/commons"
    kube_files "apply" "${dir}/${cluster}" ${env}
}


function kube_undeploy {
    dir=$1
    echo -e "${OK_COLOR}Current context: ${context}${NO_COLOR}"
    kube_directory "delete" "${dir}/commons"
    kube_directory "delete" "${dir}/${cluster}/commons"
    kube_files "delete" "${dir}/${cluster}" ${env}
}

if [ $# -eq 0 ]; then
    usage
    exit 0
fi

cluster=""
env=""
action=""
app=""
dir=""
image_tag=""

while getopts c:e:p:a:d:t:h option; do
    case "${option}"
    in
        c) cluster=${OPTARG};;
        e) env=${OPTARG};;
        p) action=${OPTARG};;
        a) app=${OPTARG};;
        d) dir=${OPTARG};;
        t) image_tag=${OPTARG};;
        h)
            usage
            exit 0
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

# DEBUG
echo "Cluster      : ${cluster}"
echo "Env          : ${env}"
echo "Action       : ${action}"
echo "Application  : ${app}"
echo "Directory    : ${dir}"
echo "Docker image : ${image_tag}"

build_number=$(date +%Y%m%d%H%M%S)

check_argument "${cluster}" "Please specify a cluster"
check_argument "${env}" "Please specify an environment"
check_argument "${app}" "Please specify an application"
check_argument "${action}" "Please specify an action to perform"
check_argument "${dir}" "Please specify a directory"
check_argument "${image_tag}" "Please specify a Docker image tag"

# exit 0

case ${cluster} in
    minikube)
        url=${minikube_url}
        ;;
    *)
        echo -e "${ERROR_COLOR}Invalid cluster: ${env}${NO_COLOR}"
        usage
        exit 1
        ;;
esac


case ${action} in
    create)
        kube_context ${cluster} ${env}
        output="/tmp/${app}"
        kube_replace ${app} ${image_tag} ${build_number} ${dir} ${output}
        kube_deploy ${output}
        ;;
    destroy)
        kube_context ${cluster} ${env}
        output="/tmp/${app}"
        kube_replace ${app} ${image_tag} ${build_number} ${dir} ${output}
        kube_undeploy ${output}
        ;;
    *)
        echo -e "${ERROR_COLOR}Invalid action: [${action}]${NO_COLOR}"
	    echo -e "Valid actions: create, destroy"
        exit 1
esac
