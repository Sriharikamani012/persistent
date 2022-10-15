#!/bin/bash

pwd 
cloud="aws"
infra_file="../../${cloud}-infra.json"
luna_inputs="../${cloud}-k8s-cluster/inputs/dev/luna-inputs.json"

customer_nm=$(python3 parse-creds.py $infra_file "customer-name")
region=$(python3 parse-creds.py $infra_file "region")
infra_version=$(python3 parse-creds.py $luna_inputs "infra-version-suffix")
vpc_id=$(python3 parse-creds.py $infra_file "vpc-id")
subnet_cidr=$(python3 parse-creds.py $infra_file "publicSubnet1")
cluster_nm="luna-${customer_nm}-k8s-00${infra_version}-eks"


./${cloud}-init-backends.sh k8s-cluster
cd ../${cloud}-k8s-cluster

#Copying Configuration for Only Linux Nodes
cp ../${cloud}-additional-configs/eks-cluster-only-linux.tf ./eks-cluster.tf

subnet_id=$(aws ec2 describe-subnets \
    --output text \
    --filters "Name=vpc-id,Values=${vpc_id}" "Name=cidr-block,Values=${subnet_cidr}" \
    --query 'Subnets[*].[SubnetId]')

#TODO IN the future this should be a breaking error - Add exit 1 
echo $subnet_id
if [ "$subnet_id" == "" ];
then 
    echo "No existing subnet to tag."
else 
    #Tag the subnet
    aws ec2 create-tags \
        --resources $subnet_id \
        --tags Key=kubernetes.io/cluster/${cluster_nm},Value=shared Key=kubernetes.io/role/elb,Value=1 Key=managedby,Value=lunaui
fi


#Get VM IP for Access
#TODO Remove
# public_ip=$(dig +short myip.opendns.com @resolver1.opendns.com)

echo "Initialize Backend - K8s Cluster"
terraform init -backend-config='inputs/dev/backend.tfvars' -reconfigure

echo "Apply - K8s Cluster"
terraform apply -var-file='inputs/dev/backend.tfvars' -var-file="inputs/dev/${cloud}-infra.json" -var-file="inputs/dev/luna-inputs.json" -parallelism=50 -auto-approve

#Report inventory
terraform state list >> ../${cloud}-scripts/inventory.txt
terraform show >> ../${cloud}-scripts/show-inventory.txt
cluster_nm=$(terraform output cluster_name)
aws_acct=$(terraform output aws_account_id)
aws_policy=$(terraform output cluster-autoscaling-policy-name)

#TODO Add this back in once the Luna Helm Charts are Updated to Support Windows Worker Nodes
#Enable Windows Worker Nodes
eksctl utils install-vpc-controllers --cluster ${cluster_nm} --approve
rm eks-cluster.tf
cp ../${cloud}-additional-configs/eks-cluster-windows.tf ./eks-cluster.tf

#Reapply Windows Cluster Configuration
echo "Apply - K8s Cluster for Windows Worker Nodes"
terraform apply -var-file='inputs/dev/backend.tfvars' -var-file="inputs/dev/${cloud}-infra.json" -var-file="inputs/dev/luna-inputs.json" -refresh=true -parallelism=50 -auto-approve

echo "Confirming Kubernetes Deployment."
kubernetes_cluster=$(aws eks describe-cluster --name ${cluster_nm})
echo $kubernetes_cluster
#Script Success Check 
if [ -z "$kubernetes_cluster" ];
then 
    echo "ERROR - Creating Kubernetes Cluster."
    ./../${cloud}-scripts/${cloud}-clean-up.sh
    exit 1
fi 


cd ../${cloud}-scripts
pwd

./aws-kubeconfig.sh
#Deploying Cluster Autoscaler 
echo "Deploying Cluster Autoscaler"
sed -i "s/REGION/$region/" ../aws-additional-configs/auto-scaling.yaml
sed -i "s/<ACCOUNT_ID>/${aws_acct}/" ../aws-additional-configs/auto-scaling.yaml
sed -i "s/CLUSTERNM/${cluster_nm}/" ../aws-additional-configs/auto-scaling.yaml
sed -i "s/<ROLE_NAME>/${aws_policy}/" ../aws-additional-configs/auto-scaling.yaml

helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm upgrade -i autoscaler autoscaler/cluster-autoscaler --values=../aws-additional-configs/auto-scaling.yaml --namespace kube-system
