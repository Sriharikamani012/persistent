#!/bin/bash

cloud="gcp"
creds="../../${cloud}-creds.json"
cd ../${cloud}-scripts

current_dir=$(pwd | grep -c ${cloud}-scripts)
if [ $current_dir -ne "1" ];
then 
    cd ${cloud}/${cloud}-scripts
fi
infra_file="../../${cloud}-infra.json"
customer_name=$(python3 parse-creds.py $infra_file "customer-name")
cluster_nm=$(gcloud container clusters list | grep -Eo "^luna-${customer_name}-k8s\S*")
cluster_zone=$(python3 parse-creds.py $infra_file "zone")
gcp_project_id=$(python3 parse-creds.py $creds "project_id")

#TODO Future Make Cloud Agnostic

gcloud auth activate-service-account --key-file=${creds}
gcloud config set project $gcp_project_id

KUBECONFIG="$HOME/.kube/config"
gcloud container clusters get-credentials ${cluster_nm} --zone ${cluster_zone} --project ${gcp_project_id}

#Confirming AWS Auth 
auth_status=$(kubectl auth can-i '*' '*' --all-namespaces | grep -c yes)
if [ $auth_status -ne 1 ] 
then
    echo "Acceptable RBAC access not enabled or provided."
    exit 1
fi

if [ $current_dir -ne "1" ];
then
    cd ../../
fi
