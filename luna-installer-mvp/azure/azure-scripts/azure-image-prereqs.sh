#!/bin/bash
# Anthos Azure Runbook  - Prerequisites 
# These are the required prereqs for the Azure Infrastructure Orchestration VM

# Python 
# https://linuxize.com/post/how-to-install-pip-on-ubuntu-18.04/
echo 'Downloading Python.' >> status.txt
sudo apt -q update
sudo apt -q install python3-pip -y
echo "Confirming Python Version" 
python3 --version >> status.txt
echo 'Python Download Complete.' >> status.txt
echo >> status.txt
echo >> status.txt


#Google SDK 
echo 'Downloading Google SDK.' >> status.txt
sudo snap install google-cloud-sdk --classic
echo 'Downloading Google SDK.' >> status.txt


#Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash


#Download Terraform (if needed)
echo 'Downloading Terraform.'
sudo apt-get -q install -y unzip
wget -nv https://releases.hashicorp.com/terraform/0.13.4/terraform_0.13.4_linux_amd64.zip
unzip terraform_0.13.4_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version >> status.txt
echo 'Terraform Download Complete.'


#Install Kubectl 
sudo snap install kubectl --classic
kubectl version --client -o yaml | grep gitVersion 
kubectl version --client -o yaml | grep gitVersion >> status.txt


#Install Helm 
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
