#!/bin/bash

#TODO May need to Update the references here depending on whether or not the customer is managing the google account or not
cloud="gcp"
service_account_creds="../../gcp-creds.json"
gcp_project_id=$(python3 parse-creds.py $service_account_creds "project_id")
infra_file="../../${cloud}-infra.json"

customer_name=$(python3 parse-creds.py $infra_file "customer-name")
cluster_nm=$(gcloud container clusters list | grep -Eo "^luna-${customer_name}-k8s\S*")
cluster_zone=$(python3 parse-creds.py $infra_file "zone")

#Gets Kubectl Configuration
gcloud container clusters get-credentials ${cluster_nm} --zone ${cluster_zone} --project ${gcp_project_id}

#Connection of Anthos to the Customer Account
for i in {1..3} # retry 3 times
do
    member_exists=$(gcloud container hub memberships list | grep -c ${cluster_nm})
    echo "Anthos member exists: ${member_exists}"
    if [  $member_exists -ne 1 ];
    then
        #Registering Anthos
        gcloud container hub memberships register ${cluster_nm} \
            --gke-cluster="${cluster_zone}/${cluster_nm}" \
            --service-account-key-file=${service_account_creds} \
            --quiet

        echo "Waiting for 2 minutes to allow anthos to be stable."
        sleep 120
    else
        echo "Anthos Membership already exists."
        exit 0
    fi
done
exit 1

