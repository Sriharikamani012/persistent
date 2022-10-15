#!/bin/bash
# This script attaches Anthos to the Azure Attached Cluster
# Home DIR = azure/azure-scripts


cloud="azure"
service_account_creds="../../gcp-creds.json"
gcp_project_id=$(python3 parse-creds.py $service_account_creds "project_id")
infra_file="../../${cloud}-infra.json"


./${cloud}-kubeconfig.sh

customer_nm=$(python3 parse-creds.py $infra_file "customer-name")
resource_group_name=$(python3 parse-creds.py $infra_file "resourceGroup")

cluster_nm=$(az aks list -g $resource_group_name --query "[].{name:name}" --output tsv | grep luna | grep $customer_nm ) 

#Confirming Azure Auth 
auth_status=$(kubectl auth can-i '*' '*' --all-namespaces | grep -c yes)
if [ $auth_status -ne 1 ] 
then
    echo "Acceptable RBAC access not enabled or provided."
    exit 
fi

kubeconfig_context=$(kubectl config current-context)
echo $kubeconfig_context

#Registering Anthos
gcloud container hub memberships register ${cluster_nm} \
        --context=${kubeconfig_context} \
        --service-account-key-file=${service_account_creds} \
        --project=${gcp_project_id} --quiet

#Temporary Anthos Patch from the Google Anthos Team, until the Connect Agent is configured to not schedule on windows nodes. 
kubectl patch deployment $(kubectl get deployment -o=jsonpath={.items[*].metadata.name} -n gke-connect) -p '{"spec":{"template":{"spec":{"nodeSelector":{"kubernetes.io/os":"linux"}}}}}' -n gke-connect

#Script Success Check 
anthos_status=$(kubectl get pods -n gke-connect)

if [ -z "$anthos_status" ];
then 
    echo "Anthos was not successfully deployed"
    ./${cloud}-clean-up.sh
    exit 1
fi 
