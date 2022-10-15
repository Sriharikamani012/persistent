#!/bin/bash
#https://github.com/prometheus-operator/kube-prometheus

# create namespace and CRDs
kubectl apply -f manifests/setup

# wait for CRD creation to complete
until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done

# create monitoring components
kubectl apply -f manifests/

