#!/bin/bash
#Home DIR = aws/aws-scripts

cloud="aws"
aws_service_creds="../../aws-creds.json"
infra_file="../../${cloud}-infra.json"

#Input Options = k8s-cluster, database, or object-storage
cd ../${cloud}-scripts

#Prequesites 
customer_nm=$(python3 parse-creds.py $infra_file "customer-name")
region=$(python3 parse-creds.py $infra_file "region")
s3_bucket=$(python3 parse-creds.py $infra_file "objectStorageName")

#Confirm S3 Bucket Exists
if [ "$s3_bucket" == "" ];
then 
    echo "No Storage Account yet, one will be created."
    echo "ERROR - Installation not successful"
    exit 1
else
    #Upload Files for the zip
    #Upload Token
    aws s3 cp ./token.txt s3://${s3_bucket}/luna-installer/token.txt

    #Upload Logs 
    aws s3 cp ./../../installation-logs.txt s3://${s3_bucket}/luna-installer/installation-logs.txt

    #Upload inventory 
    aws s3 cp ./inventory.txt s3://${s3_bucket}/luna-installer/inventory.txt

fi 

