#!/bin/bash
# Azure-init-backends.sh is a script which configures the terraform remote backend 
# and manages the state for the installer
# Home DIR = azure/azure-scripts

cloud="azure"
azure_service_creds="../../azure-creds.json"
infra_file="../../${cloud}-infra.json"

#Input Options = k8s-cluster, database, or object-storage
infra_type=${1?Error: Infrastructure type not given.}

cd ../${cloud}-scripts

#Prequesites 
customer_nm=$(python3 parse-creds.py $infra_file "customer-name")
azure_client_id=$(python3 parse-creds.py $azure_service_creds "appId")
azure_client_secret=$(python3 parse-creds.py $azure_service_creds "password")
azure_tenant_id=$(python3 parse-creds.py $azure_service_creds "tenant")
azure_subscription_id=$(python3 parse-creds.py $infra_file "subscription_id")

#parsing the ObjectStorageName and the resource group from the input json
resource_group=$(python3 parse-creds.py $infra_file "resourceGroup")
storage_acct=$(python3 parse-creds.py $infra_file "objectStorageName")
containers="${storage_acct}-installer" 

if [ "$storage_acct" == "" ];
then 
    echo "No Storage Account yet, one will be created."
else
    object_state_exists=$(az storage blob exists \
    --account-name $storage_acct \
    --container-name $containers \
    --name statefiles/luna-object-storage.tfstate \
    --auth-mode key \
    --output tsv)

    #Pull down the object storage state file (if it exists)
    if [[ $object_state_exists == "True" && ${infra_type} == "object-storage" ]];
    then
        az storage blob download \
            --account-name $storage_acct \
            --container-name $containers \
            --name statefiles/luna-object-storage.tfstate \
            --file ../${cloud}-object-storage/terraform.tfstate \
            --auth-mode key

    fi 
fi 



# Parse and Pull User inputs for Credentials
echo "subscription_id = \"$azure_subscription_id\"" >> ${infra_type}-backend.tfvars 
#appID
echo "client_id = \"$azure_client_id\"" >> ${infra_type}-backend.tfvars 
#Password
echo "client_secret = \"$azure_client_secret\"" >> ${infra_type}-backend.tfvars 
#Tenant
echo "tenant_id = \"$azure_tenant_id\"" >> ${infra_type}-backend.tfvars 
echo " " >> ${infra_type}-backend.tfvars 


#Remove Backend For Remaining infra
if [ $infra_type != "object-storage" ];
then
    #Initialize the database and cluster state files
    echo "resource_group_name = \"$resource_group\"" >> ${infra_type}-backend.tfvars 
    echo "storage_account_name = \"$storage_acct\"" >> ${infra_type}-backend.tfvars 
    echo "container_name = \"$containers\"" >> ${infra_type}-backend.tfvars 
    echo "key =\"statefiles/dev-${infra_type}-poc.tfstate\"" >> ${infra_type}-backend.tfvars 
fi

# Copy the files to the appropriate location 
# Distribute the new files
rm ../${cloud}-${infra_type}/inputs/dev/backend.tfvars
touch ../${cloud}-${infra_type}/inputs/dev/backend.tfvars
cp ./${infra_type}-backend.tfvars ../${cloud}-${infra_type}/inputs/dev/backend.tfvars
rm ${infra_type}-backend.tfvars 

cd ../${cloud}-${infra_type}
