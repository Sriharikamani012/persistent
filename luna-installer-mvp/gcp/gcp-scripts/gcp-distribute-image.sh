
family_name=gke-infra-stack-b7z6obhuevsskncw
image_name=gke-infra-stack
source_disk=gcp-installer-ami
source_zone=us-central1-a

#Create Image
gcloud compute images create $image_name \
    --source-disk $source_disk \
    --source-disk-zone $source_zone \
    --family $family_name


#Open Image to the Public
gcloud compute images add-iam-policy-binding $image_name \
    --member='allAuthenticatedUsers' \
    --role='roles/compute.imageUser'



#/projects/accenture-290518/global/images/gke-infra-stack


gcloud compute images create $image_name \
    --source-image=SOURCE_IMAGE \
    [--source-image-project=IMAGE_PROJECT] \
    --guest-os-features="FEATURES,..." \
    [--storage-location=LOCATION]



gcloud compute instances create test-imagevm \
    --image-project accenture-290518 \
    --image /projects/accenture-290518/global/images/gke-infra-stack \
    --image-family gke-infra-stack-b7z6obhuevsskncw
