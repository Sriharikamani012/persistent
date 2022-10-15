#!/bin/bash

#This script should only run for Azure and AWS to add logging and monitoring functionality to GCP.
#Run script: ./logging-monitoring-install k8s <cloud> EX: aws, azure

cloud=${2?Error: No cloud provider given.}
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
    RegionName=$(python3 ../../${cloud}/${cloud}-scripts/parse-creds.py $infra_file "region")
    echo $RegionName

    # Deployment of Cloudwatch Application Logs 
    # https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Container-Insights-setup-EKS-quickstart.html
    FluentBitHttpPort='2020'
    FluentBitReadFromHead='Off'
    [[ ${FluentBitReadFromHead} = 'On' ]] && FluentBitReadFromTail='Off'|| FluentBitReadFromTail='On'
    [[ -z ${FluentBitHttpPort} ]] && FluentBitHttpServer='Off' || FluentBitHttpServer='On'
    curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluent-bit-quickstart.yaml | sed 's/{{cluster_name}}/'${ClusterName}'/;s/{{region_name}}/'${RegionName}'/;s/{{http_server_toggle}}/"'${FluentBitHttpServer}'"/;s/{{http_server_port}}/"'${FluentBitHttpPort}'"/;s/{{read_from_head}}/"'${FluentBitReadFromHead}'"/;s/{{read_from_tail}}/"'${FluentBitReadFromTail}'"/' | kubectl apply -f - 
fi

cluster_check=$(gcloud container hub memberships list | grep -c $cluster_nm)
if [[ $cluster_check == 0 ]]
then
    echo "No attached cluster by that name!"
    exit
fi

service_account_creds="../../gcp-creds.json"
gcp_project_id=$(python3 ../../${cloud}/${cloud}-scripts/parse-creds.py $service_account_creds "project_id")
cp $service_account_creds credentials.json
kubectl create secret generic google-cloud-credentials -n kube-system --from-file credentials.json

cluster_location=$(gcloud container hub memberships describe $cluster_nm | grep name | cut -d'/' -f4)

#---------------------------------------------------------------------------
#*****Uncomment this section if enabling logging for the cluster in gcp*****
#---------------------------------------------------------------------------

#sed -i "/project_id/c\      project_id $gcp_project_id" aggregator.yaml
#sed -i "/k8s_cluster_name/c\      k8s_cluster_name $cluster_nm" aggregator.yaml
#sed -i "/k8s_cluster_location/c\      k8s_cluster_location $cluster_location" aggregator.yaml

#if [[ $cloud == "aws" ]]
#then
#    sed -i "/storageClassName: gp2/c\      storageClassName: gp2 #AWS EKS" aggregator.yaml
#elif [[ $cloud == "azure" ]]
#then
#    sed -i "/storageClassName: default/c\      storageClassName: default #Azure AKS" aggregator.yaml
#else
#    sed -i "/storageClassName: standard/c\      storageClassName: standard #GCP" aggregator.yaml
#fi

#kubectl apply -f aggregator.yaml
#kubectl apply -f forwarder.yaml

#kubectl get pods -n kube-system | grep stackdriver-log
#stackdriver_check=$(kubectl get pods -n kube-system | grep stackdriver-log | grep -c 0/1)
#logging_count=0
#while [[ $stackdriver_check -ne 0 ]] && [[ $logging_count -le 20 ]]; do
#    echo "waiting for stackdriver pods"
#    sleep 5
#    stackdriver_check=$(kubectl get pods -n kube-system | grep stackdriver-log | grep -c 0/1)
#    logging_count=$((logging_count + 1))
#done
#sleep 5
#kubectl logs stackdriver-log-aggregator-0 -n kube-system | cat > logging.txt
#log_check=$(cat logging.txt | grep -c "Successfully sent gRPC")
#
#if [[ $log_check -gt 0 ]]
#then
#    echo "Logging applied successfully"
#else
#    echo "Logging failed"
#fi

sed -i "/stackdriver.project-id=/c\        - \"--stackdriver.project-id=$gcp_project_id\"" prometheus.yaml
sed -i "/stackdriver.kubernetes.location=/c\        - \"--stackdriver.kubernetes.location=$cluster_location\"" prometheus.yaml
sed -i "/stackdriver.generic.location=/c\        - \"--stackdriver.generic.location=$cluster_location\"" prometheus.yaml
sed -i "/stackdriver.kubernetes.cluster-name=/c\        - \"--stackdriver.kubernetes.cluster-name=$cluster_nm\"" prometheus.yaml

if [[ $cloud == "aws" ]]
then
    sed -i "/storageClassName: gp2/c\        storageClassName: gp2 #AWS EKS" prometheus.yaml
elif [[ $cloud == "azure" ]]
then
    sed -i "/storageClassName: default/c\        storageClassName: default #Azure AKS" prometheus.yaml
else
    sed -i "/storageClassName: standard/c\        storageClassName: standard #GCP" prometheus.yaml
fi

kubectl apply -f server-configmap.yaml
kubectl apply -f sidecar-configmap.yaml
kubectl apply -f prometheus.yaml

monitoring_count=0
prometheus_check=$(kubectl get pods -n kube-system | grep stackdriver-prometheus | grep -c 2/2)
while [[ $prometheus_check -ne 1 ]] && [[ $monitoring_count -le 20 ]]; do
    echo "waiting for stackdriver prometheus pods"
    sleep 5
    prometheus_check=$(kubectl get pods -n kube-system | grep stackdriver-prometheus | grep -c 2/2)
    monitoring_count=$((monitoring_count + 1))
done
sleep 5
kubectl logs stackdriver-prometheus-k8s-0 -n kube-system stackdriver-prometheus-sidecar | cat > monitoring.txt
monitoring_check1=$(cat monitoring.txt | grep -c "Web server started")
monitoring_check2=$(cat monitoring.txt | grep -c "Stackdriver client started")

if [[ $monitoring_check1 -gt 0 && $monitoring_check2 -gt 0 ]]
then
    echo "Monitoring started correctly!"
else
    echo "Monitoring failed"
fi

cd external-metrics
chmod +x monitoring-deploy.sh
./monitoring-deploy.sh

KUBE_CLUSTER=$cluster_nm
GCP_PROJECT=$gcp_project_id

KUBE_NAMESPACE=monitoring
GCP_REGION=global
DATA_DIR=/prometheus/
DATA_VOLUME=prometheus-storage-volume
SIDECAR_IMAGE_TAG=0.8.1

kubectl create secret generic stackdriver-metrics-exporter-key --from-file=key.json=../credentials.json -n monitoring

#Google Documentation - https://cloud.google.com/stackdriver/docs/solutions/gke/prometheus#configuration
set -e
set -u

if [  $# -lt 1 ]; then
  echo -e "Usage: $0 <prometheus_name>\n"
  exit 1
fi

kubectl -n "${KUBE_NAMESPACE}" patch prometheus "$1" --type merge --patch "
spec:
  containers:
  - name: sidecar
    image: gcr.io/stackdriver-prometheus/stackdriver-prometheus-sidecar:${SIDECAR_IMAGE_TAG}
    imagePullPolicy: Always
    args:
    - \"--stackdriver.project-id=${GCP_PROJECT}\"
    - \"--prometheus.wal-directory=/data/wal\"
    - \"--stackdriver.kubernetes.location=${GCP_REGION}\"
    - \"--stackdriver.kubernetes.cluster-name=${KUBE_CLUSTER}\"
    ports:
    - name: sidecar
      containerPort: 9091
    volumeMounts:
    - mountPath: /data
      name: prometheus-$1-db
    - mountPath: /var/secrets/google
      name: google-cloud-key
    env:
    - name: GOOGLE_APPLICATION_CREDENTIALS
      value: /var/secrets/google/key.json
  volumes:
  - name: google-cloud-key
    secret:
      secretName: stackdriver-metrics-exporter-key
"
cd ..
sleep 10
sed -i "/displayName/c\displayName: ${cluster_nm}" dashboard.yaml 
sed -i 's/"cluster_name"=".*/"cluster_name"="'$cluster_nm'"/' dashboard.yaml
sleep 2
gcloud monitoring dashboards create --config-from-file=dashboard.yaml