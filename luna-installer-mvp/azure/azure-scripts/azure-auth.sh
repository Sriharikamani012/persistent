#!/bin/bash
# Azure Auth Script authenticates for both Azure and GCP
# This script is run in the prerequesites, so the installation will not start unless the credentials can authenticate
# Home DIR = azure/azure-scripts

service_account_creds="../../gcp-creds.json"
azure_service_creds="../../azure-creds.json"

gcp_project_id=$(python3 parse-creds.py $service_account_creds "project_id")
azure_client_id=$(python3 parse-creds.py $azure_service_creds "appId")
azure_client_secret=$(python3 parse-creds.py $azure_service_creds "password")
azure_tenant_id=$(python3 parse-creds.py $azure_service_creds "tenant")
azure_subscription_id=$(python3 parse-creds.py $azure_service_creds "tenant")

azure_status=$(az login --service-principal -u $azure_client_id -p $azure_client_secret --tenant $azure_tenant_id --query "[].{state:state}" | egrep -c "Enabled")

if [ "$azure_status" == "1" ];
then 
    echo "Authenticating Azure Successful."
else
    echo "ERROR: Authenticating Azure FAILED."
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

#Enable Required Services
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