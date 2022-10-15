#!/bin/bash

# Note:
# GCP does not require a minor version for kubernetes upgrades. Example: Running an upgrade with version 1.17 instead of 1.17.3, 
# will run and successfully upgrade the cluster / nodepool. GCP handles the minor version if it is ommitted.

# Assumptions:
# 1. that this script will be run from within the luna-installer-* repo
# 2. gcloud prerequisites have already been run beforehand. refer to gcp upgrade documentation.

# TODO: Add prerequisite steps.
# For example:move existing data into persistent disk
cloud="gcp"

infra_file="../../${cloud}-infra.json"
luna_inputs_file="../../${cloud}/${cloud}-k8s-cluster/inputs/dev/luna-inputs.json"
customer_name=$(python3 parse-creds.py $infra_file "customer-name")
location=$(python3 parse-creds.py ../../gcp-infra.json "zone")

cluster_name=$(gcloud container clusters list | grep -Eo "^luna-${customer_name}-k8s\S*")
cluster_remote_version=$(gcloud container clusters list | grep ${cluster_name} | awk '{print $3}')
target_k8s_version=${1?Error: No kubernetes version given.}
nodepools=$(gcloud container node-pools list --cluster=${cluster_name} --zone=${location} | \
  grep -o "^luna-${customer_name}-k8s.*" | awk '{print $1}')

echo "Upgrading Kubernetes Cluster"
if [[ "$cluster_remote_version" != "$target_k8s_version"* ]];
then
  gcloud container clusters upgrade ${cluster_name} --master \
    --zone=${location} \
    --cluster-version=${target_k8s_version} \
    --quiet
fi

sleep 60;

echo "Upgrading Kubernetes nodepools"
echo "$nodepools" | while read -r line; do
  current_nodepool_version=$(gcloud container node-pools describe "$line" \
    --cluster=${cluster_name} --zone=${location} | grep version | sed 's/version: //g');

  if [[ ! -z "$current_nodepool_version" && "$current_nodepool_version" != "$target_k8s_version"* ]];
  then
    echo "Upgrading node-pool: ${line}";
    gcloud container clusters upgrade ${cluster_name} \
      --zone=${location} \
      --node-pool=${line} \
      --cluster-version=${target_k8s_version} \
      --quiet;

    sleep 60;
  fi
done

cluster_remote_version=$(gcloud container clusters list | grep ${cluster_name} | awk '{print $3}')
if [[ "$cluster_remote_version" != "$target_k8s_version"* ]]
then
  echo "ERROR - Upgrade Failed. Remote cluster version and current version are not equal."
  echo "Please change the luna inputs file to specify a different version, if an upgrade was intended."
  exit 1
else
  echo "Kubernetes Cluster has been upgraded successfully."
  echo "$nodepools" | while read -r line; do
    current_nodepool_version=$(gcloud container node-pools describe "$line" \
      --cluster=${cluster_name} --zone=${location} | grep version | sed 's/version: //g');

    if [[ "$current_nodepool_version" != "$target_k8s_version"* ]];
    then
      echo "ERROR - Upgrade Failed. Kubernetes Nodepool's version does not match target version."
      exit 1
    else
      echo "Kubernetes Nodepool $line has been upgraded successfully."
    fi
  done
fi
exit 0