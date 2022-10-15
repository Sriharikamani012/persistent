#!/bin/bash

#TODO Copy the same tfvars file into all of these directories
cloud="gcp"
./${cloud}-init-backends.sh object-storage
cd ../gcp-object-storage

echo "Initialize Backend - Object Storage"
terraform init -reconfigure

echo "Destroy - Object Storage"
terraform destroy -var-file='inputs/dev/gcp-infra.json' -var-file='inputs/dev/luna-inputs.json' -refresh=true -parallelism=50 -auto-approve

cd ../gcp-scripts
python ../${cloud}-scripts/update_json.py ../../${cloud}-infra.json "objectStorageName" ""

pwd
