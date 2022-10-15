#!/bin/bash

cloud="aws"
./${cloud}-init-backends.sh object-storage
cd ../${cloud}-object-storage

echo "Initialize Backend - Object Storage"
terraform init -backend-config='inputs/dev/backend.tfvars' 

echo "Destroy - Object Storage"
terraform destroy -var-file='inputs/dev/backend.tfvars' -var-file="inputs/dev/luna-inputs.json" -var-file="inputs/dev/${cloud}-infra.json" -parallelism=50 -auto-approve

python3 ../${cloud}-scripts/update_json.py ../../${cloud}-infra.json "objectStorageName" ""

cd ../${cloud}-scripts
pwd