#!/bin/bash
#Home DIR = gcp/gcp-scripts

cloud="gcp"
gcp_service_creds="../../${cloud}-creds.json"
infra_file="../../${cloud}-infra.json"

#Input Options = k8s-cluster, database, or object-storage
cd ../${cloud}-scripts

#Prequesites 
customer_nm=$(python3 parse-creds.py $infra_file "customer-name")
region=$(python3 parse-creds.py $infra_file "region")
gcp_bucket=$(python3 parse-creds.py $infra_file "objectStorageName")

#Confirm S3 Bucket Exists
if [ "$gcp_bucket" == "" ];
then 
    echo "No Storage Account yet, one will be created."
    echo "ERROR - Installation not successful"
    exit 1
else
    #Upload Files for the zip
    #Upload Token

    #Upload Logs 
    gsutil cp ./../../installation-logs.txt gs://${gcp_bucket}/luna-installer/installation-logs.txt
    
    #Upload inventory 
    gsutil cp ./inventory.txt gs://${gcp_bucket}/luna-installer/inventory.txt

fi 

