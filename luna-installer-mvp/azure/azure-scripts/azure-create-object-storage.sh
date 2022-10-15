#!/bin/bash
# Azure-create-object-storage.sh deploys an Azure Storage account
# This storage account will host the installer state files and Luna Platform Object Storage
# Please see the ../azure-object-storage directory for further specifications
# Home DIR = azure/azure-scripts

cloud="azure"
infra_file="../../${cloud}-infra.json"
customer_nm=$(python3 parse-creds.py $infra_file "customer-name")
./${cloud}-init-backends.sh object-storage
cd ../${cloud}-object-storage

echo "Initialize Backend - Object Storage"
terraform init -backend-config='inputs/dev/backend.tfvars' 

echo "Apply - Object Storage"
terraform apply -var-file='inputs/dev/backend.tfvars' -var-file="inputs/dev/luna-inputs.json" -var-file="inputs/dev/${cloud}-infra.json" -auto-approve

#Upload to Object Storage 
storage_acct_name=$(terraform output storage-account-name)
python3 ../${cloud}-scripts/update_json.py ../../${cloud}-infra.json "objectStorageName" $storage_acct_name
python3 ../${cloud}-scripts/update_json.py ../../${cloud}-frontend.json "objectStorageName" $storage_acct_name

resource_group_name=$(terraform output resource-group)
python3 ../${cloud}-scripts/update_json.py ../../${cloud}-infra.json "resourceGroup" $resource_group_name
python3 ../${cloud}-scripts/update_json.py ../../${cloud}-frontend.json "resourceGroup" $resource_group_name


storage_acct=$(az storage account list -g $resource_group_name --query "[].{name:name}" --output tsv | grep $storage_acct_name)
containers="${storage_acct_name}-installer" 

#Script Success Check 
if [ -z "$storage_acct" ];
then 
    exit 1
else
    #Upload to newly created storage account
    az storage blob upload \
        --account-name $storage_acct_name \
        --container-name $containers \
        --file ./terraform.tfstate \
        --name statefiles/luna-object-storage.tfstate \
        --auth-mode key 
    
    #Certificates have been removed prior to uploading to the object storage
    #Upload tfvars json file to newly created storage account
    az storage blob upload \
        --account-name $storage_acct_name \
        --container-name $containers \
        --name azure-infra.json \
        --file "../../${cloud}-frontend.json" \
        --auth-mode key 

fi 

#Report inventory 
terraform state list >> ../${cloud}-scripts/inventory.txt
terraform show >> ../${cloud}-scripts/show-inventory.txt

cd ../${cloud}-scripts
pwd