#!/bin/bash
cloud="gcp"
./${cloud}-init-backends.sh database
#TODO Copy the same tfvars file into all of these directories
cd ../gcp-k8s-cluster
#vpc_name=$(terraform output vpc_name)

cd ../gcp-database

echo "Initialize Backend - Database"
terraform init -backend-config='inputs/dev/backend.tfvars' -reconfigure

echo "Apply - Database"
terraform apply -var-file='inputs/dev/backend.tfvars' -var-file='inputs/dev/gcp-infra.json' -var-file='inputs/dev/luna-inputs.json' -refresh=true -parallelism=50 -auto-approve

#Report inventory 
terraform state list >> ../gcp-scripts/inventory.txt
terraform show >> ../gcp-scripts/show-inventory.txt

cd ../gcp-scripts
pwd

#TODO Update Once GCP is set up 
sed -i "s/host.domain/""/" ../../artifacts/ingress-values.yaml
sed -i "s/<PASSWORD>/""/" ../../artifacts/ingress-values.yaml


DATABASE_INSTANCE_NAME=$(terraform output database_instance_name)
db_instance_exists=$(gcloud sql instances list | grep "$DATABASE_NAME")

if [ -z "$db_instance_exists" ];
then
    echo "Error - Database instance was not provisioned."
    ../../${cloud}-scripts/${cloud}-clean-up.sh
    exit 1
fi