#!/bin/bash

#TODO Helm List to get the current installations
helm ls -a --all-namespaces | awk 'NR > 1 { print  "-n "$2, $1}' | xargs -L1 helm delete

kubectl delete pvc --all --all-namespaces

echo ""
echo "Luna Pods"
kubectl get pods --all-namespaces

echo ""
echo "Luna Services"
kubectl get services --all-namespaces

echo ""
echo "Luna Ingress"
kubectl get ingress --all-namespaces

echo ""
echo "Luna Secrets"
kubectl get secrets --all-namespaces

echo ""
echo "Luna Deployments"
kubectl get deployments --all-namespaces


echo "Luna Nodes"
kubectl get nodes 