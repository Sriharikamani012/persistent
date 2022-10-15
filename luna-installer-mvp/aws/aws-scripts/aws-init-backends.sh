#!/bin/bash
#Home DIR = aws/aws-scripts

cloud="aws"
aws_service_creds="../../aws-creds.json"
infra_file="../../${cloud}-infra.json"

#Input Options = k8s-cluster, database, or object-storage
infra_type=${1?Error: Infrastructure type not given.}
cd ../${cloud}-scripts

#Prequesites 
customer_nm=$(python3 parse-creds.py $infra_file "customer-name")
region=$(python3 parse-creds.py $infra_file "region")
s3_bucket=$(python3 parse-creds.py $infra_file "objectStorageName")

#Confirm S3 Bucket Exists
if [[ $s3_bucket != "" && ${infra_type} == "object-storage" ]];
then 
    #Pull down terraform.tfstate for the object storage
    aws s3 cp s3://${s3_bucket}/luna-installer/statefiles/luna-object-storage.tfstate ../${cloud}-object-storage/terraform.tfstate
fi 

#Region  
echo "region =\"$region\"" >> ${infra_type}-backend.tfvars
aws configure set region $region

#Create Remote Backend For Remaining Infra
if [ $infra_type != "object-storage" ];
then
    #Bucket Id
    echo "bucket = \"$s3_bucket\"" >> ${infra_type}-backend.tfvars 
    #Key
    echo "key =\"luna-installer/statefiles/dev-${infra_type}-poc.tfstate\"" >> ${infra_type}-backend.tfvars  
fi

# Copy the files to the appropriate location 
# Distribute the new files
rm ../${cloud}-${infra_type}/inputs/dev/backend.tfvars
touch ../${cloud}-${infra_type}/inputs/dev/backend.tfvars
cp ./${infra_type}-backend.tfvars ../${cloud}-${infra_type}/inputs/dev/backend.tfvars
rm ${infra_type}-backend.tfvars 

cd ../${cloud}-${infra_type}
