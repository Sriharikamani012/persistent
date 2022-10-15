/*************************************************************************
 General Customer Inputs
*************************************************************************/
variable "customer-name" {
  type        = string
  description = "The name of the bucket where the state file will be stored. This bucket needs to be configured with the appropriate permissions to enable the service principal to get/update the statefile."
}

variable "infra-version-suffix" {
  type        = number
  description = "This variable allows the user to specify the infrastructure's version number within the naming convention. If the value is empty, the default will be 1. Ex. luna-ncis-vpc-001"
}

/*************************************************************************
 Kubernetes Specifications Variables
*************************************************************************/
variable "k8s-version" {
  type        = string
  description = "Kubernetes release version."
  default     = "1.17"
}

/*************************************************************************
 Encryption Key Variables  
*************************************************************************/
variable "kms-master-key-id" {
  default     = ""
  description = "If a KMS Key ARN is set, this key will be used to encrypt the corresponding log group. Additionally, it will encrypt etcd. Please be sure that the KMS Key has an appropriate key policy (https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/encrypt-log-data-kms.html)"
  type        = string
}


/*************************************************************************
 RBAC, IAM & Security Variables 
*************************************************************************/
variable "cluster-security-group-id" {
  description = "If provided, the EKS cluster will be attached to this security group. If not given, a security group will be created with necessary ingress/egress to work with the workers"
  type        = string
  default     = ""
}

# variable "cluster-endpoint-devops-access-cidr" {
#   description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint."
#   type        = list(string)
# }

variable "cluster-create-security-group" {
  description = "Whether to create a security group for the cluster or attach the cluster to `cluster_security_group_id`."
  type        = bool
  default     = true
}

variable "service-account-id" {
  description = "The ARN for the service account."
  type        = string
}

variable "service-account-name" {
  description = "The name of the AWS Service Account."
  type        = string
}

variable "aws-account-num" {
  description = ""
  type        = string
}

/*************************************************************************
 Tags 
*************************************************************************/
variable "cluster-tags" {
  default = {
    Environment = "test"
    Project     = "Luna"
    Customer    = ""
  }
  description = "The resource tags for the cluster."
  type        = map(string)
}

