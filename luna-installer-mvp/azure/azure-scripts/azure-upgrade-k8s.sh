#!/bin/bash
# https://docs.microsoft.com/en-us/azure/aks/upgrade-cluster
# The Node Pool will scale up and cordon the nodes one by one. The node will be drained of pods, and the pods will be re-assigned to a new node.
# This will continue to occur until all nodes have been replaced with the appropriate version.

cloud="azure"
# Pull Desired K8s version from luna installer inputs
desired_k8s_version=${1?Error: No kubernetes version given.}

infra_file="../../${cloud}-infra.json"
luna_inputs_file="../${cloud}-k8s-cluster/inputs/dev/luna-inputs.json"
customer_nm=$(python3 parse-creds.py $infra_file "customer-name")
resource_group=$(python3 parse-creds.py $infra_file "resourceGroup")
cluster_nm=$(az aks list -g $resource_group --query "[].{name:name}" --output tsv | grep luna-$customer_nm-k8s)

# TODO remove in the future
# Temporary update because of sudden version change
# k8s version 1.16 was suddenly depricated on 2/9/20 - https://github.com/Azure/AKS/releases/tag/2021-02-01
desired_k8s_version="1.18" 

# Get Available Version for the region
available_version=$(az aks get-upgrades --resource-group $resource_group --name $cluster_nm --query 'controlPlaneProfile.upgrades[0].kubernetesVersion' --output json)
version_available=$(echo $available_version | grep -c $desired_k8s_version)
if [ $version_available -ne 1 ]
then 
    echo "Upgrade version is not available for this region. Please contact Thermo Fisher Support to ensure that the Luna Cluster is meeting minimum kubernetes requirements. "
    exit 1 
else
    echo "Upgrade to version $available_version is available."
fi

#Version was approved - continue to set new variable
desired_k8s_version=$(echo "$available_version" | tr -d '"')
./${cloud}-kubeconfig.sh
creds="../../${cloud}-creds.json"

# This section can be removed upon using az cli 1.16
# Install the aks-preview extension
az extension add --name aks-preview
# Update the extension to make sure you have the latest version installed
az extension update --name aks-preview

# TODO Add max surge for the node pools
# Upgrade Cluster Version
az aks upgrade \
    --resource-group $resource_group  \
    --name $cluster_nm \
    --kubernetes-version $desired_k8s_version --yes


server_version=$(kubectl version --short | grep Server | grep -c $desired_k8s_version)
nodes_version=$(kubectl get nodes | grep -c $desired_k8s_version)

if [[ $server_version == 0 && $nodes_version == 0 ]]
then
    ./azure-clean-up.sh
    echo "Error: upgrading kubernetes version. Contact Thermo Fisher to attempt manual upgrade."
    exit 1
fi

echo "Successfully upgraded kubernetes version ${desired_k8s_version}"

cd ../../