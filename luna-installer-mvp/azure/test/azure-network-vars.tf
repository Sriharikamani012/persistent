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

variable "region" {
  type        = string
  default      = "eastus2"
  description = "The azure region for the deployment."
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

