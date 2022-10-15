#!/bin/bash
cloud="gcp"
./${cloud}-init-backends.sh k8s-cluster
cd ../gcp-k8s-cluster

echo "Initialize Backend - K8s Cluster"
terraform init -backend-config='inputs/dev/backend.tfvars' -reconfigure

echo "Apply - K8s Cluster"
terraform apply -var-file='inputs/dev/backend.tfvars' -var-file='inputs/dev/gcp-infra.json' -var-file='inputs/dev/luna-inputs.json' -refresh=true -parallelism=50 -auto-approve

#Report inventory 
terraform state list >> ../gcp-scripts/inventory.txt
terraform show >> ../gcp-scripts/show-inventory.txt

cluster_nm=$(terraform output cluster_name)
cluster_zone=$(terraform output cluster_zone)
#TODO Add Taint for window worker nodes.

cd ../gcp-scripts
pwd

k8s_cluster_exists=$(gcloud container clusters list --zone="$cluster_zone" | grep $cluster_nm)

if [ -z $k8s_cluster_exists ];
then
    echo "Error - GCP Kubernetes Cluster was not provisioned."
    ../../${cloud}-scripts/${cloud}-clean-up.sh
    exit 1
fi