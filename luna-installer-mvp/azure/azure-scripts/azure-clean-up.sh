#!/bin/bash
# This script is run upon an installation success or failure, and will upload the following files to the Storage Account
# Files Uploaded - token.txt, installation-logs.txt, inventory.txt
# Home DIR = azure/azure-scripts

cloud="azure"
infra_file="../../${cloud}-infra.json"

cd ../${cloud}-scripts

#Prequesites 
customer_nm=$(python3 parse-creds.py $infra_file "customer-name")
region=$(python3 parse-creds.py $infra_file "region")
storage_acct_name=$(python3 parse-creds.py $infra_file "objectStorageName")
resource_group=$(python3 parse-creds.py $infra_file "resourceGroup")
containers="${storage_acct_name}-installer" 

#Confirm Storage Account Bucket Exists
if [ "$storage_acct_name" == "" ];
then 
    echo "Storage Account does not exist."
    exit 1
else
    #Upload Token
    az storage blob upload \
        --account-name $storage_acct_name \
        --container-name $containers \
        --name token.txt \
        --file ./token.txt \
        --auth-mode key 

    #Upload Logs 
    az storage blob upload \
        --account-name $storage_acct_name \
        --container-name $containers \
        --name installation-logs.txt \
        --file ./../../installation-logs.txt \
        --auth-mode key 

    #Upload inventory 
    az storage blob upload \
        --account-name $storage_acct_name \
        --container-name $containers \
        --name inventory.txt \
        --file ./inventory.txt \
        --auth-mode key 

fi 

