#!/bin/bash

cloud="azure"
creds="../../${cloud}-creds.json"
cd ../${cloud}-scripts

infra_file="../../${cloud}-infra.json"
customer_nm=$(python3 parse-creds.py $infra_file "customer-name")
resource_group_name=$(python3 parse-creds.py $infra_file "resourceGroup")
cluster_nm=$(az aks list -g $resource_group_name --query "[].{name:name}" --output tsv | grep luna-$customer_nm-k8s) 

#Script Success Check 
if [ -z "$cluster_nm" ];
then 
    exit 1
fi
   
KUBECONFIG="$HOME/.kube/config"
az aks get-credentials --name $cluster_nm --resource-group $resource_group_name  --overwrite-existing

#Confirming AWS Auth 
auth_status=$(kubectl auth can-i '*' '*' --all-namespaces | grep -c yes)
if [ $auth_status -ne 1 ] 
then
    echo "Acceptable RBAC access not enabled or provided."
    exit 1
fi

cd ../../