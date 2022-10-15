#!/bin/bash
#Home DIR = aws/aws-scripts

cloud="aws"
aws_service_creds="../../aws-creds.json"
infra_file="../../${cloud}-infra.json"

# #Input Options = k8s-cluster, database, or object-storage
# cd ../${cloud}-scripts

#Prequesites 
s3_bucket=$(python3 parse-creds.py $infra_file "objectStorageName")

#Confirm S3 Bucket Exists
if [ "$s3_bucket" == "" ];
then 
    echo "No Storage Account yet"
    echo "ERROR - Upgrade not successful"
    exit 1
else
    #Upload Logs 
    aws s3 cp ./../../installation-logs.txt s3://${s3_bucket}/luna-installer/update-logs.txt

fi 
