#!/bin/bash

cloud="aws"
./${cloud}-init-backends.sh k8s-cluster
cd ../${cloud}-k8s-cluster

echo "Initialize Backend - K8s Cluster"
terraform init -backend-config='inputs/dev/backend.tfvars' -reconfigure

echo "Destroy - K8s Cluster"
terraform destroy -var-file='inputs/dev/backend.tfvars' -var-file="inputs/dev/${cloud}-infra.json" -var-file="inputs/dev/luna-inputs.json" -auto-approve -parallelism=50

#Report inventory 
terraform state list >> ../${cloud}-scripts/inventory.txt
terraform show >> ../${cloud}-scripts/show-inventory.txt

cd ../${cloud}-scripts
pwd