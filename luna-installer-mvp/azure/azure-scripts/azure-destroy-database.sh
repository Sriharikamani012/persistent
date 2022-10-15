#!/bin/bash
# Azure-destroy-database.sh destroys a Postgres database in Azure 
# Please see the ../azure-database directory for further specifications
# Home DIR = azure/azure-scripts
cloud="azure"
./${cloud}-init-backends.sh database
cd ../${cloud}-database

echo "Initialize Backend - Database"
terraform init -backend-config='inputs/dev/backend.tfvars' -reconfigure

echo "Destroy - Database"
terraform destroy -var-file='inputs/dev/backend.tfvars' -var-file="inputs/dev/luna-inputs.json" -var-file="inputs/dev/${cloud}-infra.json" -auto-approve

#Report inventory 
terraform state list >> ../${cloud}-scripts/inventory.txt
terraform show >> ../${cloud}-scripts/show-inventory.txt

cd ../${cloud}-scripts
pwd