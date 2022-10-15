#!/bin/bash
# Unregister Azure Attached Cluster from Anthos

#Inputs Required
service_account_creds="../../gcp-creds.json"
gcp_project_id=$(python3 parse-creds.py $service_account_creds "project_id")
cloud="azure"
infra_file="../../${cloud}-infra.json"

./${cloud}-kubeconfig.sh

customer_nm=$(python3 parse-creds.py $infra_file "customer-name")
resource_group_name=$(python3 parse-creds.py $infra_file "resourceGroup")
cluster_nm=$(az aks list -g $resource_group_name --query "[].{name:name}" --output tsv | grep luna | grep $customer_nm ) 

#Confirming AWS Auth 
auth_status=$(kubectl auth can-i '*' '*' --all-namespaces | grep -c yes)
if [ $auth_status -ne 1 ] 
then
    echo "Acceptable RBAC access not enabled or provided."
    exit 
fi

kubeconfig_context=$(kubectl config current-context)
echo $kubeconfig_context

gcloud container hub memberships unregister ${cluster_nm} \
   --project=${gcp_project_id} \
   --context=${kubeconfig_context} --quiet

