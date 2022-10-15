#!/bin/bash
#    Anthos-AWS RBAC Authorization
#    
#    This script creates a service account and binds the role to the cluster. A token is outputted at the end of the file, 
#    which will be needed to authenticate the cluster in the GCP Console. 
#
#    Current Limitation - the authentication of the cluster in the GCP console is manual at the moment. 
#
#    - Navigate to the Anthos Dashboard 
#    - Select Cluster status
#    - Select the name of your user cluster you deployed (ex. cluster-0)
#    - A login prompt will be in the top right hand corner 
#    - Select Token and paste the token outputed from this script into the console. 

#https://www.arctiq.ca/our-blog/2020/4/30/multi-cloud-app-deployment-across-aws-and-gcp-with-google-anthos/
# Create an admin user in the user cluster
kubectl create serviceaccount -n kube-system admin-user

# Assign the correct rolebinding to the user user
kubectl create clusterrolebinding admin-user-binding \
    --clusterrole cluster-admin --serviceaccount kube-system:admin-user

# Get the token name assigned to the newly created admin service account (send in a ticket for this)
SECRET_NAME=$( \
  kubectl get serviceaccount -n kube-system admin-user -o jsonpath='{$.secrets[0].name}')

# Get the token
token=$(kubectl get secret -n kube-system ${SECRET_NAME} -o jsonpath='{$.data.token}' \
  | base64 -d | sed $'s/$/\\\n/g')

rm -f token.txt
echo $token
echo $token >> token.txt
#TODO Secure this File

