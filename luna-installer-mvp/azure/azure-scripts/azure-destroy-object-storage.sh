#!/bin/bash
# Azure-destroy-object-storage.sh destroys an Azure Storage account
# This will result in Data loss for the customer
# Please see the ../azure-object-storage directory for further specifications
# Home DIR = azure/azure-scripts

cloud="azure"
./${cloud}-init-backends.sh object-storage
cd ../${cloud}-object-storage

echo "Initialize Backend - Object Storage"
terraform init -backend-config='inputs/dev/backend.tfvars' 

echo "Destroy - Object Storage"
terraform destroy -var-file='inputs/dev/backend.tfvars' -var-file="inputs/dev/luna-inputs.json" -var-file="inputs/dev/${cloud}-infra.json" -auto-approve

python3 ../${cloud}-scripts/update_json.py ../../${cloud}-infra.json "objectStorageName" ""
python3 ../${cloud}-scripts/update_json.py ../../${cloud}-infra.json "resourceGroup" ""

cd ../${cloud}-scripts
pwd