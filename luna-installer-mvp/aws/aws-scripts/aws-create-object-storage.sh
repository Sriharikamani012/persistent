#!/bin/bash

cloud="aws"
infra_file="../../${cloud}-infra.json"
./${cloud}-init-backends.sh object-storage
cd ../${cloud}-object-storage

echo "Initialize Backend - Object Storage"
terraform init -backend-config='inputs/dev/backend.tfvars' 

echo "Apply - Object Storage"
terraform apply -var-file='inputs/dev/backend.tfvars' -var-file="inputs/dev/luna-inputs.json" -var-file="inputs/dev/${cloud}-infra.json" -refresh=true -parallelism=50 -auto-approve

#Get S3 Bucket Output Name 
bucket_name=$(terraform output this-s3-bucket-id)
python3 ../${cloud}-scripts/update_json.py ../../${cloud}-infra.json "objectStorageName" $bucket_name
python3 ../${cloud}-scripts/update_json.py ../../${cloud}-frontend.json "objectStorageName" $bucket_name

#Confirm S3 Bucket Exists
s3_bucket=$(aws s3api list-buckets --query "Buckets[].Name" | grep luna | grep $bucket_name)
s3_bucket=$(echo $s3_bucket | tr -d '"')

#Script Success Check 
if [ -z "$s3_bucket" ];
then 
    echo "ERROR: creating bucket."
    exit 1
else
    #Upload to newly created S3 Bucket State File
    aws s3 cp ./terraform.tfstate s3://${bucket_name}/luna-installer/statefiles/luna-object-storage.tfstate

    #Upload tfvars json file to newly created storage account
    aws s3 cp ../../aws-frontend.json s3://${bucket_name}/luna-installer/aws-infra.json
fi

#Report inventory 
terraform state list >> ../${cloud}-scripts/inventory.txt
terraform show >> ../${cloud}-scripts/show-inventory.txt

cd ../${cloud}-scripts
pwd