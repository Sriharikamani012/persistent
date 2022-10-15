#!/bin/bash

cloud="gcp"
infra_file="../../${cloud}-infra.json"
./${cloud}-init-backends.sh object-storage
cd ../${cloud}-object-storage

echo "Initialize Backend - Object Storage"
terraform init -reconfigure

echo "Apply - Object Storage"
terraform apply -var-file='inputs/dev/gcp-infra.json' -var-file='inputs/dev/luna-inputs.json' -refresh=true -parallelism=50 -auto-approve

bucket_name=$(terraform output bucket_name)
python3 ../${cloud}-scripts/update_json.py ../../${cloud}-infra.json "objectStorageName" $bucket_name
python3 ../${cloud}-scripts/update_json.py ../../${cloud}-frontend.json "objectStorageName" $bucket_name

#Bucket name
gsutil cp ./terraform.tfstate gs://${bucket_name}/luna-installer/statefiles/gcp-objectstorage/default.tfstate
gsutil cp ../../${cloud}-frontend.json gs://${bucket_name}/luna-installer/${cloud}-infra.json

#Report inventory 
terraform state list >> ../gcp-scripts/inventory.txt
terraform show >> ../gcp-scripts/show-inventory.txt

cd ../gcp-scripts
pwd

bucket_exists=$(gsutil ls | grep $bucket_name)

if [[ -z "$bucket_exists" ]];
then
    echo "Object Storage bucket was not provisioned."
    ../../${cloud}-scripts/${cloud}-clean-up.sh
    exit 1
fi
