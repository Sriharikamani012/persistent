#!/bin/bash
  
#Home Directory - gcp/gcp-scripts
#Get Cloud 
cloud=${1?Error: No cloud given.}
lb_type=${2?Error: No load balancer type given.}

customer_inputs="../../${cloud}-infra.json"
customer_name=$(python3 parse_creds.py $customer_inputs "customer-name")
custom_dns=$(python3 parse_creds.py $customer_inputs "custom-dns")
customer_secret=${customer_name}-auto-ingress-secret
#TODO Upload Template of the helm-override.yaml to repo, but remove the AWS Credentials
#TODO update code when we are able to pass the values for crt and key
key_file=$(python3 parse_creds.py $customer_inputs "key-file-name")
cert_file=$(python3 parse_creds.py $customer_inputs "cert-file-name")
#append cert and key to files to be used in create secret later
#create secret
if [[ -f ../../$key_file && -f ../../$cert_file ]];
then 
    echo "Updating the certificates."
    kubectl delete secret ${customer_secret} --ignore-not-found --namespace default
    kubectl create secret tls ${customer_secret} --namespace default --key ../../${key_file} --cert ../../${cert_file}
fi
#Adding helm repo 
#TODO Add version to this pull 
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
#add nginx lb 
helm upgrade -i nginx-ingress ingress-nginx/ingress-nginx -f ./nginx-values/${cloud}-${lb_type}.yaml --namespace default 

#edit helm-override file for client
sed -i "s/luna.local/${custom_dns}/" ../../artifacts/ingress-values.yaml
sed -i "/secretName/c\   - secretName: ${customer_secret}" ../../artifacts/ingress-values.yaml


kubectl get services