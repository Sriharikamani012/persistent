#!/bin/bash

#Prereqs Permissions
#https://cloud.google.com/anthos/multicluster-management/connect/prerequisites#gcloud_auth

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

#Auto Approve the re-installation or check if it is installed and install or don't install it
#Registering Anthos
gcloud container hub memberships register ${cluster_nm} \
  --context=${kubeconfig_context} \
  --service-account-key-file=${service_account_creds} \
  --project=${gcp_project_id} \
  --quiet

kubectl patch deployment $(kubectl get deployment -o=jsonpath={.items[*].metadata.name} -n gke-connect) -p '{"spec":{"template":{"spec":{"nodeSelector":{"kubernetes.io/os":"linux"}}}}}' -n gke-connect

#Script Success Check 
anthos_status=$(kubectl get pods -n gke-connect)
if [ -z "$anthos_status" ];
then 
    echo "Anthos was not successfully deployed"
    ./${cloud}-clean-up.sh
    exit 1
fi 
