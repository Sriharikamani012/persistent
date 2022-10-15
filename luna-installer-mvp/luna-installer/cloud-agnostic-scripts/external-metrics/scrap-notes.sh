export KUBE_NAMESPACE=monitoring
export KUBE_CLUSTER=luna-jamess3log-k8s-001-eks
export GCP_REGION=global
export GCP_PROJECT=accenture-290518
export DATA_DIR=/prometheus/
export DATA_VOLUME=prometheus-storage-volume
export SIDECAR_IMAGE_TAG=0.3.2

kubectl -n "${KUBE_NAMESPACE}" get deployment prometheus-deployment -o=go-template='{{$output := "stackdriver-prometheus-sidecar does not exist."}}{{range .spec.template.spec.containers}}{{if eq .name "sidecar"}}{{$output = (print "stackdriver-prometheus-sidecar exists. Image: " .image)}}{{end}}{{end}}{{printf $output}}{{"\n"}}'


kubectl -n "${KUBE_NAMESPACE}" get deployment prometheus-deployment

sg="Unrecoverable error sending samples to remote storage" err="google: could not find default credentials. See https://developers.google.com/accounts/docs/application-default-credentials for more information."

#https://cloud.google.com/stackdriver/docs/solutions/gke/prometheus 
#scripts for sidecar - https://github.com/Stackdriver/stackdriver-prometheus-sidecar/tree/master/kube
#getting started with prometheus - https://prometheus.io/docs/prometheus/latest/getting_started/
#https://github.com/GoogleCloudPlatform/anthos-samples/tree/master/attached-logging-monitoring
#https://medium.com/google-cloud/prometheus-and-stackdriver-fb8f7524ece0
#https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity
kubectl create namespace prometheus

kubectl create serviceaccount --namespace prometheus owner-cluster-admin-binding

#Add Workload Identity 
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:accenture-290518.svc.id.goog[monitoring/default]" \
  bastionsa-gcp@accenture-290518.iam.gserviceaccount.com


# annotate service account
kubectl annotate serviceaccount \
  --namespace monitoring \
  default \
  iam.gke.io/gcp-service-account=bastionsa-gcp@accenture-290518.iam.gserviceaccount.com



gcloud iam service-accounts create kops-metrics-exporter \
    --description="metrics exporter from kops cluster" \
    --display-name="Kops Metric Exporter"

gcloud projects add-iam-policy-binding accenture-290518 \
    --member="serviceAccount:kops-metrics-exporter@accenture-290518.iam.gserviceaccount.com" \
    --role="roles/logging.logWriter"

gcloud projects add-iam-policy-binding accenture-290518 \
    --member="serviceAccount:kops-metrics-exporter@accenture-290518.iam.gserviceaccount.com" \
    --role="roles/monitoring.metricWriter"


kubectl create secret generic stackdriver-metrics-exporter-key --from-file=key.json=./workdir/kops-metrics-exporter.json -n monitoring


kubectl -n "${KUBE_NAMESPACE}" patch deployment prometheus-deployment --type merge --patch "
spec:
  containers:
  - name: sidecar
    image: gcr.io/stackdriver-prometheus/stackdriver-prometheus-sidecar:${SIDECAR_IMAGE_TAG}
    imagePullPolicy: Always
    args:
    - \"--stackdriver.project-id=${GCP_PROJECT}\"
    - \"--prometheus.wal-directory=/prometheus/wal\"
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



kubectl -n "${KUBE_NAMESPACE}" patch pod prometheus-deployment-595b5768c9-bqgjm --type merge --patch "
spec:
  containers:
  - name: sidecar
    image: gcr.io/stackdriver-prometheus/stackdriver-prometheus-sidecar:${SIDECAR_IMAGE_TAG}
    imagePullPolicy: Always
    args:
    - \"--stackdriver.project-id=${GCP_PROJECT}\"
    - \"--prometheus.wal-directory=/prometheus/wal\"
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
