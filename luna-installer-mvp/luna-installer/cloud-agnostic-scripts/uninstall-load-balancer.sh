#!/bin/bash
  
#Home Directory - gcp/gcp-scripts
#Get Cloud 
cloud=${1?Error: No cloud given.}
lb_type=${2?Error: No load balancer type given.}

#Add helm repo 
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
#Add nginx lb 
helm delete nginx-ingress ingress-nginx/ingress-nginx 

kubectl get services