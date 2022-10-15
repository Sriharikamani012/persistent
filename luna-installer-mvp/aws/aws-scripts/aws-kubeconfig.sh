#!/bin/bash
pwd
#Home Dir - Scripts

cloud="aws"
infra_file="../../${cloud}-infra.json"
luna_inputs="../${cloud}-k8s-cluster/inputs/dev/luna-inputs.json"

current_dir=$(pwd | grep -c ${cloud}-scripts)
if [ $current_dir -ne "1" ]; 
then 
    cd ${cloud}/${cloud}-scripts
fi 

KUBECONFIG="$HOME/.kube/config"
customer_nm=$(python3 parse-creds.py $infra_file "customer-name")
region=$(python3 parse-creds.py $infra_file "region")
infra_version=$(python3 parse-creds.py $luna_inputs "infra-version-suffix")
cluster_nm="luna-${customer_nm}-k8s-00${infra_version}-eks"

aws eks update-kubeconfig --name ${cluster_nm} --region ${region}

#Confirming AWS Auth 
auth_status=$(kubectl auth can-i '*' '*' --all-namespaces | grep -c yes)
if [ $auth_status -ne 1 ]; 
then
    echo "Acceptable RBAC access not enabled or provided."
    exit 1
fi


if [ $current_dir -ne "1" ]; 
then 
    cd ../../
fi 
