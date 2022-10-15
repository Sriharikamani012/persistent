#!/bin/bash
#This script is Cloud Agnostic

#Take in Key Value Pair
secret_nm=${1?Error: No secret given.}
secret_value=${2?Error: No secret value given.}

#secretName
secret_nm=$(python3 parse-creds.py $azure_service_creds "secretName")

cp ../aws-additional-configs/aws-secret.yaml aws-secret.yaml

search1="my-secret"
search2="myPassword"

if [[ $search1 != "" && $secret_nm != "" ]]; then
sed -i "s/$search1/$secret_nm/gi" aws-secret.yaml 
fi

if [[ $search2 != "" && $secret_value != "" ]]; then
sed -i "s/$search2/$secret_value/gi" aws-secret.yaml 
fi

#Apply Secret into the cluster
kubectl apply -f aws-secret.yaml

#Remove file for security  
rm aws-secret.yaml
