#!/bin/bash
# Azure-destroy-k8s-cluster.sh destroys the private k8s cluster 
# and a few corresponding network components that were deployed 
# to secure the cluster and allow appropriate connectivity  
# Please see the ../azure-k8s-cluster directory for further specifications
# Home DIR = azure/azure-scripts

cloud="azure"
./${cloud}-init-backends.sh k8s-cluster
cd ../${cloud}-k8s-cluster

echo "Initialize Backend - K8s Cluster"
terraform init -backend-config='inputs/dev/backend.tfvars' -reconfigure

echo "Destroy - K8s Cluster"
terraform destroy -var-file='inputs/dev/backend.tfvars' -var-file="inputs/dev/luna-inputs.json" -var-file="inputs/dev/${cloud}-infra.json" -auto-approve

#Report inventory 
terraform state list >> ../${cloud}-scripts/inventory.txt
terraform show >> ../${cloud}-scripts/show-inventory.txt

cd ../${cloud}-scripts
pwd