#!/bin/bash
# Unregister AWS Attached Cluster from Anthos

#Inputs Required
cloud="gcp"
service_account_creds="../../gcp-creds.json"
gcp_project_id=$(python3 parse-creds.py $service_account_creds "project_id")
infra_file="../../${cloud}-infra.json"
customer_name=$(python3 parse-creds.py $infra_file "customer-name")
cluster_nm=$(gcloud container clusters list | grep -Eo "^luna-${customer_name}-k8s\S*")
cluster_zone=$(python3 parse-creds.py $infra_file "zone")

gcloud container hub memberships unregister ${cluster_nm} \
   --project=${gcp_project_id} \
   --gke-cluster="${cluster_zone}/${cluster_nm}" --quiet

