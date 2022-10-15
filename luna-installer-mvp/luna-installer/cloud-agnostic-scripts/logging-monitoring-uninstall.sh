#!/bin/bash

#This script should only run for Azure and AWS to add logging and monitoring functionality to GCP.
#Run script: ./logging-monitoring-uninstall

cloud=${1?Error: No cloud provider given.}


cd external-metrics
chmod +x monitoring-uninstall.sh
./monitoring-uninstall.sh

cd ..
kubectl delete secret google-cloud-credentials -n kube-system
kubectl delete -f prometheus.yaml
kubectl delete -f sidecar-configmap.yaml
kubectl delete -f server-configmap.yaml



#if logging is enabled uncomment these deletes
#kubectl delete -f forwarder.yaml
#kubectl delete -f aggregator.yaml

#Delete dashboard
infra_file="../../${cloud}-infra.json"
luna_inputs="../../${cloud}/${cloud}-k8s-cluster/inputs/dev/luna-inputs.json"
customer_nm=$(python3 ../../${cloud}/${cloud}-scripts/parse-creds.py $infra_file "customer-name")
infra_version=$(python3 ../../${cloud}/${cloud}-scripts/parse-creds.py $luna_inputs "infra-version-suffix")

if [[ $cloud == azure ]]
then
    # Azure Monitor Natively Exports Application Logs
    cluster_nm="luna-${customer_nm}-k8s-00${infra_version}-aks"
else
    cluster_nm="luna-${customer_nm}-k8s-00${infra_version}-eks"
    ClusterName=$cluster_nm
    RegionName=$(python3../../${cloud}/${cloud}-scripts/parse-creds.py $infra_file "region")

    #Delete AWS CloudWatch 
    curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml | sed "s/{{cluster_name}}/'${ClusterName}'/;s/{{region_name}}/'${RegionName}'/" | kubectl delete -f -
fi

dash_id=$(gcloud monitoring dashboards list --filter=displayName:$cluster_nm --format="value(name)")
#Script Success Check 
if [ ! -z "$dash_id" ];
then 
    gcloud monitoring dashboards delete $dash_id --quiet
fi

