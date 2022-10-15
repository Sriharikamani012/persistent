#!/bin/bash
# Azure-create-k8s-cluster.sh deploys a private k8s cluster 
# and a few corresponding network components to secure the cluster and allow appropriate connectivity  
# Please see the ../azure-k8s-cluster directory for further specifications
# Home DIR = azure/azure-scripts

cloud="azure"
infra_file="../../${cloud}-infra.json"
customer_nm=$(python3 parse-creds.py $infra_file "customer-name")
resource_group=$(python3 parse-creds.py $infra_file "resourceGroup")
cp ../../azure-infra.json ../azure-k8s-cluster/inputs/dev/azure-infra.json
./${cloud}-init-backends.sh k8s-cluster

service_account_creds="../../gcp-creds.json"
azure_service_creds="../../azure-creds.json"

gcp_project_id=$(python3 parse-creds.py $service_account_creds "project_id")
azure_client_id=$(python3 parse-creds.py $azure_service_creds "appId")
azure_client_secret=$(python3 parse-creds.py $azure_service_creds "password")
azure_tenant_id=$(python3 parse-creds.py $azure_service_creds "tenant")
azure_subscription_id=$(python3 parse-creds.py $azure_service_creds "tenant")
cd ../${cloud}-k8s-cluster

echo "Initialize Backend - K8s Cluster"
terraform init -backend-config='inputs/dev/backend.tfvars' -reconfigure

echo "Apply - K8s Cluster"
terraform apply -var-file='inputs/dev/backend.tfvars' -var-file="inputs/dev/luna-inputs.json" -var-file="inputs/dev/${cloud}-infra.json" -auto-approve

#Report inventory
terraform state list >> ../${cloud}-scripts/inventory.txt
terraform show >> ../${cloud}-scripts/show-inventory.txt

cluster_name=$(terraform output cluster_name) 
kubernetes_cluster=$(az aks list -g $resource_group  --query "[].{name:name}" --output tsv | grep $cluster_name) 

#Script Success Check 
if [ -z "$kubernetes_cluster" ];
then 
    ./${cloud}-clean-up.sh
    exit 1
else
    #Success - Get Kubeconfig
    resource_group_name=$(terraform output resource_group_name)
    az aks get-credentials --name $cluster_name --resource-group $resource_group_name --overwrite-existing
fi 


#Temporary Node Taint
kubectl taint nodes akslunaw000000 key=value:NoSchedule 
kubectl taint nodes akslunaw000001 key=value:NoSchedule 
kubectl taint nodes akslunaw000002 key=value:NoSchedule 

cd ../${cloud}-scripts
pwd