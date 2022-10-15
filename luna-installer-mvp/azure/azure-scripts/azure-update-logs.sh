#!/bin/bash
#Home DIR = azure/azure-scripts

cloud="azure"
azure_service_creds="../../azure-creds.json"
infra_file="../../${cloud}-infra.json"


#Prequesites 
customer_nm=$(python3 parse-creds.py $infra_file "customer-name")
region=$(python3 parse-creds.py $infra_file "region")
storage_acct_name=$(python3 parse-creds.py $infra_file "objectStorageName")
resource_group=$(python3 parse-creds.py $infra_file "resourceGroup")
containers="${storage_acct_name}-installer" 

#Confirm S3 Bucket Exists
if [ "$storage_acct_name" == "" ];
then 
    echo "Storage Account does not exist."
    exit 1
else
    #Upload Logs 
    az storage blob upload \
        --account-name $storage_acct_name \
        --container-name $containers \
        --name update-logs.txt \
        --file ./../../installation-logs.txt \
        --auth-mode key 

fi 