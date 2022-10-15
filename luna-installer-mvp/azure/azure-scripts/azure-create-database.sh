#!/bin/bash
# Azure-create-database.sh deploys a Postgres database in Azure 
# Daily backups are configured through azurerm_recovery_services_vault
# Please see the ../azure-database directory for further specifications
# Home DIR = azure/azure-scripts


cloud="azure"
infra_file="../../${cloud}-infra.json"
customer_nm=$(python3 parse-creds.py $infra_file "customer-name")
resource_group=$(python3 parse-creds.py $infra_file "resourceGroup")
cp ../../azure-infra.json ../azure-database/inputs/dev/azure-infra.json
./${cloud}-init-backends.sh database
cd ../${cloud}-database

echo "Initialize Backend - Database"
terraform init -backend-config='inputs/dev/backend.tfvars' -reconfigure

echo "Apply - Database"
terraform apply -var-file='inputs/dev/backend.tfvars' -var-file="inputs/dev/luna-inputs.json" -var-file="inputs/dev/${cloud}-infra.json" -auto-approve

#Report inventory 
terraform state list >> ../${cloud}-scripts/inventory.txt
terraform show >> ../${cloud}-scripts/show-inventory.txt

database_exists=$(az postgres db list --resource-group $resource_group --server luna-$customer_nm-psql-001 --query "[].{name:name}" --output tsv) 

#TODO Update Once Azure is set up 
sed -i "s/host.domain/""/" ../../artifacts/ingress-values.yaml
sed -i "s/<PASSWORD>/""/" ../../artifacts/ingress-values.yaml


#Script Success Check 
if [ -z "$database_exists" ];
then 
    ./${cloud}-clean-up.sh
    exit 1
else
    #Success - Database exists
    echo "Successfully deployed DB."
fi 


cd ../${cloud}-scripts
pwd