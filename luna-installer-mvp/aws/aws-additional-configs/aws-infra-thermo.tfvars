/*************************************************************************
 AWS Account Information
*************************************************************************/
customer-name           = "ncis"
infra-version-suffix    = 1

aws-account-num         = "078680276960"
service-account-id      = "arn:aws:iam::078680276960:user/terraform_tfs_poc"
service-account-name    = "terraform_tfs_poc"

gcp_project_id          = "accenture-290518"
management_sa           = "anthos-sample-service-account"

service_account_creds   = "../../../google-sa.json"

/*************************************************************************
 AWS Encryption & Security Variables 
*************************************************************************/
kms-master-key-id = "arn:aws:kms:us-east-2:078680276960:key/24b1395e-43da-4b5f-ae74-e4a1af47d60d"

/*************************************************************************
 AWS S3
*************************************************************************/
#Placeholder for AWS Access Policy 

/*************************************************************************
 Tags 
*************************************************************************/
cluster-tags = { 
    Environment = "test"
    Project     = "Luna"
    Customer  = ""
  }

/*************************************************************************
 AWS Networking & Security Variables
*************************************************************************/
vpc-cidr                     = "10.0.0.0/16" 
private-subnets              = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"] 
public-subnets               = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"] 
  
/*************************************************************************
 AWS RDS Specific Inputs
*************************************************************************/
#Append VPC ID With an Output from the script
#vpc-id            = "vpc-05d6f0163ff31b915" 

/*************************************************************************
 AWS Kubernetes Variables 
*************************************************************************/
k8s-version             = "1.16" 
#Cluster DevOps End-Point IP will be added