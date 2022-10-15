#!/bin/bash
cloud="gcp"
./${cloud}-init-backends.sh database
#TODO Remove in the future
cd ../gcp-k8s-cluster
#vpc_name=$(terraform output vpc_name)

cd ../gcp-database

echo "Initialize Backend - K8s Cluster"
terraform init -backend-config='inputs/dev/backend.tfvars' -reconfigure

echo "Destroy - K8s Cluster"
terraform destroy -var-file='inputs/dev/backend.tfvars' -var-file='inputs/dev/gcp-infra.json' -var-file='inputs/dev/luna-inputs.json' -refresh=true -parallelism=50 -auto-approve

#Report inventory 
terraform state list >> ../gcp-scripts/inventory.txt
terraform show >> ../gcp-scripts/show-inventory.txt

cd ../gcp-scripts
pwd
