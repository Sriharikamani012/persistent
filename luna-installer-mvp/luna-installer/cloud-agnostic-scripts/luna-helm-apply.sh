#!/bin/bash

chart_path=${1?Error: No Chart Path Given.}
chart_name=${2?Error: No Chart Name Given.}
chart_namespace=${3?Error: No Namespace Given.}
values_files=${4?Error: No string containing values files provided.}

echo "Deploying $chart_path."

echo "Checking for existing deployments."
helm list -n $chart_namespace

echo "Installing Helm Charts"
#helm upgrade -i luna luna-0.1.0.tgz -f ./helm-override.yaml -f ./ingress-values.yaml
helm upgrade -i $chart_name $chart_path --namespace $chart_namespace $values_files -f ./ingress-values.yaml --create-namespace    

#TODO Status Check to confirm that the installation was successful 

cd ..

echo ""
echo "Luna Pods"
kubectl get pods -n $chart_namespace

echo ""
echo "Luna Services"
kubectl get services -n $chart_namespace

echo ""
echo "Luna Ingress"
kubectl get ingress -n $chart_namespace

echo ""
echo "Luna Secrets"
kubectl get secrets -n $chart_namespace

echo ""
echo "Luna Deployments"
kubectl get deployments -n $chart_namespace

echo ""
echo "Luna Nodes"
kubectl get nodes 


#TODO Ask Roger about the tests built into the helm charts
# helm test $chart_name -n $chart_name


