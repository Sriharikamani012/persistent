#!/bin/bash

#Home DIR = gcp/gcp-scripts

cloud="gcp"
gcp_service_creds="../../gcp-creds.json"
infra_file="../../${cloud}-infra.json"


#Input Options = k8s-cluster, database, or object-storage
infra_type=${1?Error: Infrastructure type not given.}

cd ../${cloud}-scripts

#Prequesites 
customer_nm=$(python3 parse-creds.py $infra_file "customer-name")
gcp_bucket=$(python3 parse-creds.py $infra_file "objectStorageName")
prefix_cluster="gcp-cluster"
prefix_database="gcp-database"

#Querying for a resource group with luna and rg in it but not MC_ (the resource group created for the AKS Cluster)

if [[ $gcp_bucket != "" && ${infra_type} == "object-storage" ]];
then 
    gsutil cp gs://${gcp_bucket}/luna-installer/statefiles/gcp-objectstorage/default.tfstate ../${cloud}-object-storage/terraform.tfstate
fi 



# Parse and Pull User inputs for Credentials


#Remove Backend For Remaining infra
if [ $infra_type == "k8s-cluster" ];
then
    #Bucket Id
    echo "bucket = \"$gcp_bucket\"" >> ${infra_type}-backend.tfvars 
    #prefix
    echo "prefix =\"luna-installer/statefiles/$prefix_cluster\"" >> ${infra_type}-backend.tfvars  
fi

if [ $infra_type == "database" ];
then
    #Bucket Id
    echo "bucket = \"$gcp_bucket\"" >> ${infra_type}-backend.tfvars 
    #prefix
    echo "prefix =\"luna-installer/statefiles/$prefix_database\"" >> ${infra_type}-backend.tfvars  
fi

# Copy the files to the appropriate location 
# Distribute the new files

rm ../${cloud}-${infra_type}/inputs/dev/backend.tfvars
touch ../${cloud}-${infra_type}/inputs/dev/backend.tfvars
cp ./${infra_type}-backend.tfvars ../${cloud}-${infra_type}/inputs/dev/backend.tfvars
rm ${infra_type}-backend.tfvars 

cd ../${cloud}-${infra_type}
