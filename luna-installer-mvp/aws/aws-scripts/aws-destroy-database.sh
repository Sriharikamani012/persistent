#!/bin/bash
cloud="aws"

./${cloud}-init-backends.sh database
cd ../${cloud}-database

echo "Initialize Backend - Database"
terraform init -backend-config='inputs/dev/backend.tfvars' -reconfigure

echo "Destroy - Database"
terraform destroy -var-file='inputs/dev/backend.tfvars' -var-file="inputs/dev/${cloud}-infra.json" -var-file="inputs/dev/luna-inputs.json" -parallelism=50 -auto-approve

#Report inventory 
terraform state list >> ../${cloud}-scripts/inventory.txt
terraform show >> ../${cloud}-scripts/show-inventory.txt

cd ../${cloud}-scripts
pwd