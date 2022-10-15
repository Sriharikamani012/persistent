#!/bin/bash
# Unregister AWS Attached Cluster from Anthos
#Inputs Required

cloud="aws"
aws_service_creds="../../aws-creds.json"
infra_file="../../${cloud}-infra.json"
luna_inputs="../${cloud}-k8s-cluster/inputs/dev/luna-inputs.json"
service_account_creds="../../gcp-creds.json"
gcp_project_id=$(python3 parse-creds.py $service_account_creds "project_id")

customer_nm=$(python3 parse-creds.py $infra_file "customer-name")
region=$(python3 parse-creds.py $infra_file "region")
infra_version=$(python3 parse-creds.py $luna_inputs "infra-version-suffix")
cluster_nm="luna-${customer_nm}-k8s-00${infra_version}-eks"

./${cloud}-kubeconfig.sh

#Confirming AWS Auth 
auth_status=$(kubectl auth can-i '*' '*' --all-namespaces | grep -c yes)
if [ $auth_status -ne 1 ] 
then
    echo "Acceptable RBAC access not enabled or provided."
    exit 
fi


kubeconfig_context=$(kubectl config current-context)
echo $kubeconfig_context

#Script Success Check 
anthos_status=$(kubectl get pods -n gke-connect)
if [ ! -z "$anthos_status" ];
then 
    gcloud container hub memberships unregister ${cluster_nm} \
      --project=${gcp_project_id} \
      --context=${kubeconfig_context} \
      --quiet
fi 


