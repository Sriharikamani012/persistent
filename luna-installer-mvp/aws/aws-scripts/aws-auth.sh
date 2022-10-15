#!/bin/bash

service_account_creds="../../gcp-creds.json"
aws_service_creds="../../aws-creds.json"
gcp_project_id=$(python3 parse-creds.py $service_account_creds "project_id")
aws_access_key_id=$(python3 parse-creds.py $aws_service_creds "accessKeyId")
aws_secret_access_key=$(python3 parse-creds.py $aws_service_creds "secretAccessKey")

# Status Check to Confirm the Authentication worked
aws_status1=$(aws configure set aws_access_key_id $aws_access_key_id)
aws_status2=$(aws configure set aws_secret_access_key $aws_secret_access_key)

if [[ "$aws_status1" == "" && "$aws_status2" == "" ]];
then 
    echo "Authenticating AWS Successful."
else
    echo "ERROR: Authenticating AWS FAILED."
    exit 1 
fi

gcloud_output1="$(gcloud auth activate-service-account --key-file=$service_account_creds 2>&1)"
gcloud_output2="$(gcloud config set project $gcp_project_id 2>&1)"
gcloud_status1=$(echo $gcloud_output1 | egrep -c "Activated service account credentials for:")
gcloud_status2=$(echo $gcloud_output2 | egrep -c "Updated property ")

if [ "$gcloud_status1" == "1" ];
then 
    echo "Authenticating GCP Successful."
else
    echo "ERROR: Authenticating GCP FAILED."
    exit 1
fi

if [ "$gcloud_status2" != "1" ];
then 
    echo "ERROR: Setting GCP Project."
    exit 1
fi

#Required API's
declare -a StringArray=("cloudresourcemanager.googleapis.com" "gkehub.googleapis.com" "gkeconnect.googleapis.com" "logging.googleapis.com" "monitoring.googleapis.com" "serviceusage.googleapis.com" "stackdriver.googleapis.com" "storage-api.googleapis.com" "storage-component.googleapis.com")
 
# Iterate the string array using for loop
for val in ${StringArray[@]}; do
   echo $val
   enabled=$(gcloud services list | grep -c $val)

   if [ "$enabled" != "1" ];
   then 
        echo "Enabling $val"
        gcloud services enable $val --async
   fi
done

exit 0 