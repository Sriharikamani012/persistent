#!/bin/bash
#https://github.com/prometheus-operator/kube-prometheus


# monitoring components
kubectl delete -f manifests/

# create namespace and CRDs
kubectl delete -f manifests/setup

