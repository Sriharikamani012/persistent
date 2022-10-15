
# Prerequisites 

## AWS Access Requirements 
- AWS User Access
    - Documentation regarding the User's required permissions can be found in the Thermo_Fisher Scientific_AWS_User_Policy_Update.docx in the Accenture-Documentation Repo.
- GCP Service Account Access Requirements
    - Gkehub.endpoints.connect
    - Gkehub.memberships.create 
    - Gkehub.memberships.delete
    - Gkehub.memberships.generateConnectManifest
    - Gkehub.memberships.get
    - Gkehub.memberships.list
    - Gkehub.operations.get
    - Iam.serviceAccounts.list
    - Logging.logEntries.create
    - Monitoring.dashboards.create
    - Monitoring.dashboards.list
    - Monitoring.dashboards.delete
    - Monitoring.metricDescriptors.create
    - Monitoring.metricDescriptors.get
    - Monitoring.metricDescriptors.list
    - Monitoring.monitoredResourceDescriptors.get
    - Monitoring.monitoredResourceDescriptors.list
    - Monitoring.timeSeries.create
    - Resourcemanager.projects.get
    - Resourcemanager.projects.getIamPolicy
    - Resourcemanager.projects.setIamPolicy 
    - Serviceusage.services.enable
    - Serviceusage.services.list

## Installer Version Requirements 
Software | Version | 
--- | --- | 
AWS CLI  | v2.0.57 | 
Azure CLI  | v2.14 | 
GCloud SKD | v314.0.0 | 
Helm  | v3 |
Kubectl |  gitVersion: v1.19.0 | 
Python  | v3.6.9 | 
Terraform | v0.13.4 | 
Ubuntu | 18.04 LTS | 

# General Installation Instructions

## Updating the Helm Charts and the Helm Override File ##
Update

## Creating a New Tar ##

1. Download the _testing_ branch from git 
    - if you are on Windows
2. Remove all Temporary json files (aws-infra.json, azure-infra.json, gcp-infra.json)
3. tar cvzf luna-installer-all-v1.1.tar.gz luna-installer-mvp

### Creating Helm Override ###
These steps are prereqs for the upload of the helm-override.yaml in the UI
1. Create helm-override.yaml and save it in a local directory 
    1. Update helm-override.yaml file in the artifacts directory with the required secrets
    2. Leave the host and TLS section as is, as those inputs will be updated dynamically with the customer's inputs
    3. Save the helm-override.yaml file in a readily available place to upload into the UI


## Updating the Luna Installer UI with a New Infrastructure Tar ##

1. git clone https://cmd-sw.visualstudio.com/accenture/_git/aws-tfs-electron
2. git checkout dev
3. Add your new tar into the src\files folder
4. Find and replace all instances of the old tar name and replace it with the new infrastructure tar's name (created above)
5. From the aws-tfs-electron directory install the dependencies by running
    ```
    npm install 
    ```
6. Build and package the app (automatic)

    To build as a Mac application:

    ```
    npm run package-mac
    ```

    To build as a Windows application:

    ```
    npm run package-win
    ```
7. Navigate to the Release Folder in the aws-tfs-electrion repo and open the executable 

## Running the AWS Install Journey ##
Prior to running the install please review the supported regions section for AWS. 

1. Select the install Journey
2. Add in your GCP Credentials
3. Add in your AWS Credentials
4. Fill out the form with the UI inputs
    - See User Inputs Sections for further details
    - Select regions from current supported regions: us-east-1, us-east-2, us-west-1, us-west-2 (Section below provides more details -AWS Supported Regions)
5. Next you will need to upload the following files: 
    - helm-override.yaml - See __Creating Helm Override__ Section above for instructions on how to create it
    - installation-package.tar.gz
        - For a sample testing tar please go here - TODO
        - For more information regarding this tar please refer to the __Application Specific Support__ section in the Design Document 
            - Link: https://teams.microsoft.com/l/file/F835044B-7379-4965-9BEC-9BB1B24AF946?tenantId=b67d722d-aa8a-4777-a169-ebeb7a6a3b67&fileType=docx&objectUrl=https%3A%2F%2Fthermofisher.sharepoint.com%2Fsites%2FAccentureLunaDocumentation%2FShared%20Documents%2FGeneral%2FLuna%20Platform%20Installer%20-%2001%20-%20Design%20Document.docx&baseUrl=https%3A%2F%2Fthermofisher.sharepoint.com%2Fsites%2FAccentureLunaDocumentation&serviceName=teams&threadId=19:9eee8f799644461cbb644ca027386b5d@thread.tacv2&groupId=f717f1a8-b493-4789-952c-3c9c7e4ca7f7
6. Create the EC2 Instance 
7. Will take 3-5 minutes to complete
8. Copy the files over to the EC2 instance
9. Run the scripts
10. Watch the log output
11. Wait ~15-20 minutes for the installation to complete
12. Confirm that Luna has been installed
    - Confirm expected pods are running
13. Confirm that Anthos has been correctly connected to the cluster 
14. Log into Anthos (See section below)
15. Update the DNS Record (if you have questions refer to the Accenture Documentation Repo for further instructions)
16. Confirm Luna endpoints are accessable:
    - domain-name/
    - identity.domain-name/
    - api.domain-name/audit

### Logging into Anthos for AWS
1. Log into your AWS Portal 
2. Navigate to S3
3. Find your Luna S3 Bucket 
    - The buckets follow the following naming convention:
        __luna-{customer abbreviation}-s3-{random hash}-001__
4. Navigate into the luna-installer directory
5. Download the token.txt file
6. Log into the GCP console in the project dedicated to attaching Anthos
7. Navigate to the Anthos Page
8. Click Login and use your token from the S3 bucket to authenticate
9. Securly browse the information within the GCP console


### Testing Database Connectivity from the Cluster 
1. Prior to shutting down the virtual machine in the UI
2. Log into the VM 
3. Get the database password from the outputs database outputs 
    - cd aws/aws-database
    - terraform output
4. Deploy a pod using the database-test-pod.yaml in the testing folder
5. Exec into the pod 
    - kubectl exec -it -n default shell-demo bash
6. Run the following commands from within the pod
    1. apt -q update
    2. apt-get -y install postgresql
    3. psql --host=lunatinardspostgresxzqaflchrtrajiep.cspxj2kekh31.us-east-2.rds.amazonaws.com --port=5432 --username=lunaplatform --password --dbname=lunatinardspostgresxzqaflchrtrajiep
        -  (replace the host, and dbname with the correct values, which can be located in the terraform outputs or the AWS Console)
7. Confirm that you were successful in logging into the database and the connection did not time out

## Running the AWS Upgrade Journey
The Upgrade journey will upgrade the kubernetes version to 1.17 if needed and it will upgrade the helm charts with the most recent tar in the installer. 

1. Select the upgrade Journey
2. Add in your GCP Credentials
3. Add in your AWS Credentials
4. Paste in the name of the S3 bucket, which was created during the installation 
    - The buckets follow the following naming convention:
        __luna-{customer abbreviation}-s3-{random hash}-001__
5. Next you will need to upload the following files: 
    - helm-override.yaml - See __Creating Helm Override__ Section above for instructions on how to create it
    - installation-package.tar.gz
        - For a sample testing tar please download the following - https://cmd-sw.visualstudio.com/accenture/_git/luna-installer-mvp?path=%2Ftesting%2Finstallation-package.tar.gz&version=GBdev&_a=contents 
        - For more information regarding this tar please refer to the __Application Specific Support__ section in the Design Document 
            - Link: https://teams.microsoft.com/l/file/F835044B-7379-4965-9BEC-9BB1B24AF946?tenantId=b67d722d-aa8a-4777-a169-ebeb7a6a3b67&fileType=docx&objectUrl=https%3A%2F%2Fthermofisher.sharepoint.com%2Fsites%2FAccentureLunaDocumentation%2FShared%20Documents%2FGeneral%2FLuna%20Platform%20Installer%20-%2001%20-%20Design%20Document.docx&baseUrl=https%3A%2F%2Fthermofisher.sharepoint.com%2Fsites%2FAccentureLunaDocumentation&serviceName=teams&threadId=19:9eee8f799644461cbb644ca027386b5d@thread.tacv2&groupId=f717f1a8-b493-4789-952c-3c9c7e4ca7f7
6. Create the EC2 Instance
7. Will take 3-5 minutes to complete
8. Copy the files over to the EC2 instance
9. Run the upgrade scripts
10. Watch the log output
11. Wait ~25-35 minutes for the upgrade to complete
12. Confirm that the node's kubernetes version has updated through the AWS Portal or in the Anthos Portal
13. Confirm that Luna is back up and running (It may take some time for the pods to come up on the new nodes)

## Running the AWS Uninstall Journey 
Running this journey will uninstall all active infrastructure. The database, kubernetes cluster and S3 bucket will be deleted, so be certain prior to running this journey. There will be a final database snapshot that will be available following the uninstall, however, the data in S3 will be perminently deleted. 
1. Select the uninstall Journey
2. Add in your GCP Credentials
3. Add in your AWS Credentials
4. Paste in the name of the S3 bucket, which was created during the installation 
    - The buckets follow the following naming convention:
        __luna-{customer abbreviation}-s3-{random hash}-001__
5. Fill out the TFVARS File name with: __luna-installer/aws-infra.json__
6. Create the EC2 Instance
7. Will take 3-5 minutes to complete
8. Copy the files over to the EC2 instance
9. Run the uninstall scripts
10. Watch the log output
11. Wait ~15-20 minutes for the uninstall to complete

## AWS Supported Regions ##
Currently the following regions are supported in the installer: 
```bash
    {
    "us-east-2": "ami-0b9679f9509e275c3",
    "us-east-1": "ami-08ca58e9808b44877",
    "us-west-1": "ami-0a73a448ba7deb389",
    "us-west-2": "ami-04541b9b52aaf7394"
    }
```
### Adding Additional Regions
#### Infrastructure Update Steps
1. Update the aws-ami-copy.sh script with the desired regions to copy the public ami to
2. Run the Script
```bash
./aws-ami-copy.sh
```
3. Following the script completion confirm that the public AMI's now reside in the desired regions

These steps are required, because AWS AMI's are regional. In the future, it may be worth considering using Artifactory or another method to make the AMI publically accessable. It is worth noting that while the AMI's are public they contain no Thermo Fisher proprietary information. The image contains prerequesites such as python, helm, gcloud, and the aws cli. 

#### UI Update Steps
Need to fill in description

##Enabling Logging on GCP
By default forwarding logs to the GCP project is disabled. Some customers may not want logs being aggragated there. However, if this changes, logging can be enabled through the following steps.
1. Navigate into the luna-installer directory 
2. Then go into the cloud-agnostic-scripts directory
3. There is a bash script called **logging-monitoring-install.sh**
4. Inside this file is a prominent section commented out. Uncomment this section to enable logs in GCP. Save file
5. Back in the cloud-agnostic-scripts is another file called **logging-monitoring-uninstall** 
6. Inside that file is another small commented out section. Uncomment those kubectl commands and save the file

# Troubleshooting: 
 ## If you see errors during any of the journeys
- DO NOT shut down the Virtual Machine in the Installer
- Retrieve the virtual machine's key from the following directory to: 
    - ex. C:\Users\user.name\luna_files (but modified for your user)
- Go into the cloud's portal and to grab the IP of the Installer virtual machine
- SSH into the vm

### Checklist
1. Confirm that both credential files (gcp-creds.json and aws-creds.json) have been transfered properly
2. Confirm that the luna-installer-mvp tar appropriatly unzipped
3. Confirm that the <cloud name>-infra.json is present 
    - Open the file and confirm that all of the inputs are presenting as you would expect it to
4. Confirm helm-override.yaml has been transfered 
5. If all of those prerequesites are present then depending on the error try to run the scripts again through the UI
6. If the error persists, determine the next steps based on the error messages

## Finding Logs
Logs will be present only after the python script is kicked of, if there is any failure prior to the python scripts the logs will not be available. Additionally, if the object storage is not created then the logs will only be available on the VM and will not be found in S3. 

### Logs in S3
1. Log into AWS Managment Console
2. Navigate to S3
3. Find your Luna S3 Bucket 
    - The buckets follow the following naming convention:
        __luna-{customer abbreviation}-s3-{random hash}-001__
4. Navigate into the luna-installer directory
5. Find and download the log file for your specific journey: 
    - install - installation-logs.txt
### Logs on the Installer VM
1. SSH into the VM 
2. cd into the luna-installer-mvp directory
3. open installation-logs.txt to view the logs 

# User Inputs Data Dictionary
## General Inputs
Inputs | Description | Type | Required |
--- | --- | --- | --- | 
Customer Name | The credential file for the service account with the permissions specified above. | STRING | Required |
VPC CIDR Range | The IP addresses to be used in the Luna installation to create the VPC. Ex. "10.0.0.0/16" | STRING | Required |
Certificate | The customer's signed certificate, which meets specifications that can be found in the user guide | STRING | Required |
Certificate Key | The corresponding key to the customer's signed certificate | STRING | Required |


### AWS Inputs
Inputs | Description | Type | Required |
--- | --- | --- | --- | 
AWS Account Number | The identification number for the AWS account, where the customer would like the infrastructure installed. | STRING |  Required |
AWS Access Key Id | Service Account Credential for the AWS User | STRING |  Required |
AWS Secret Access Key | Service Account Credential Secret for the AWS User | STRING |  Required |
Service Account ARN | The ARN for the service account with the permissions specified above. | STRING |  Required |
Service Account Name | The name of the service account with the permissions specified above. | STRING |  Required |
KMS Master Key ARN | The ARN of the KMS encryption key for the installation to use, which is located in the same region as the desired infrastructure.  | STRING |  Required |


### Google Cloud Inputs for Azure and AWS
Inputs | Description | Type | Required |
--- | --- | --- | --- |
Google Project ID | A Google Cloud project identification number, where Anthos will be enabled. | STRING | Required |
Google Service Account Name | The name of the service account with the permissions specified above. | STRING | Required |
Google Service Account Credentials JSON | The credential file for the service account with the permissions specified above. | JSON File | Required |

### Azure Inputs
Inputs | Description | Type | Required |
--- | --- | --- | --- | 
Subscription ID | The identification number for the Azure account, where the customer would like the infrastructure installed. | STRING |  Required |
Region | The Region for the infrastructure to be installed. | STRING |  Currently only tested in useast2 |
Service Principal Credentials| Credentials file for the azure service principal, will be the output of the azure cli command to create the service principal | JSON File |  Required |
Secret Name | Name of the secret to be used as the key for the secret deployed in the Kubernetes Cluster | STRING | Optional |
Secret Value | Value of the secret deployed in the Kubernetes Cluster. | STRING | Optional |

### Google Cloud for GCP (Needs to Be Updated)
Inputs | Description | Type | Required |
--- | --- | --- | --- |
Google Project ID | A Google Cloud project identification number, where Anthos will be enabled. | STRING | Required |
Google Service Account Name | The name of the service account with the permissions specified above. | STRING | Required |
Google Service Account Credentials JSON | The credential file for the service account with the permissions specified above. | JSON File | Required |
Private cluster master ipv4 | The ipv4 of the master cluster in Kubernetes | STRING | Required |
Vpc name | The name of the generated vpc | STRING | Required
Vpc subnetwork name | The name of the generated vpc subnetwork | STRING | Required

## Certificate Creation Steps
Create the certificate and the private key. We can use Lets Encrypt, Terraform, and AWS to create a free signed certificate. Documentation here - > https://registry.terraform.io/providers/vancluever/acme/latest/docs 

### ----OR----

Create a self-signed certificate for now using these commands:

```bash 
openssl req -x509 -nodes -days 365 -newkey rsa:2048 /    

-out <cert-filename.pem> /   

-keyout <privatekey-filename.key> /   

-subj "/CN=<Host Common Name>/O=<Host Common Name>" /   

-addext "subjectAltName = DNS:<Host Common Name>,DNS:*.<Host Common Name>"  
```

 
```bash
Example: 

openssl req -x509 -nodes -days 365 -newkey rsa:2048 /    

-out test-ingress-tls.pem /   

-keyout test-ingress-tls.key /   

-subj "/CN=lunachart.gcp.lunapp.info/O=test-ingress-tls" /   

-addext "subjectAltName = DNS:lunachart.gcp.lunapp.info,DNS:*.lunachart.gcp.lunapp.info"  
```
