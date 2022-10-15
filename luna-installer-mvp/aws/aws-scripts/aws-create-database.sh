#!/bin/bash

cloud="aws"
./${cloud}-init-backends.sh database
cd ../${cloud}-database

echo "Initialize Backend - Database"
terraform init -backend-config='inputs/dev/backend.tfvars' -reconfigure

echo "Apply - Database"
terraform apply -var-file='inputs/dev/backend.tfvars' -var-file="inputs/dev/${cloud}-infra.json" -var-file="inputs/dev/luna-inputs.json" -parallelism=50 -auto-approve

#TODO Add Error Check to AWS Database 
db_instance_id=$(terraform output db-instance-name)
describe_instance="$(aws rds describe-db-instances --db-instance-identifier $db_instance_id --query "DBInstances[].DBInstanceIdentifier" 2>&1)"
db_exists=$(echo $describe_instance | egrep -c "DBInstanceNotFound" )

db_endpoint=$(terraform output db-instance-address)
db_password=$(terraform output db-instance-password)

sed -i "s/host.domain/${db_endpoint}/" ../../artifacts/ingress-values.yaml
sed -i "s/<PASSWORD>/${db_password}/" ../../artifacts/ingress-values.yaml



#Script Success Check 
if [ "$db_exists" == "1" ];
then
    echo "ERROR - Creating Postgres Database."
    ./../${cloud}-scripts/${cloud}-clean-up.sh
    exit 1
fi

#Report inventory 
terraform state list >> ../${cloud}-scripts/inventory.txt
terraform show >> ../${cloud}-scripts/show-inventory.txt

cd ../${cloud}-scripts
pwd