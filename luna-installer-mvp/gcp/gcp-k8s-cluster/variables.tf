/*************************************************************************
 Vars - Variables declared from values passed in by .tfvars
*************************************************************************/
variable "infra-version-suffix" {
  type        = number
  description = "This variable allows the user to specify the infrastructure's version number within the naming convention. If the value is empty, the default will be 1. Ex. luna-ncis-vpc-001"
}

variable "customer-name" {
  type        = string
  description = "The name of the bucket where the state file will be stored. This bucket needs to be configured with the appropriate permissions to enable the service principal to get/update the statefile."
}

variable "gcp_project_id" {
  type        = string
  description = "The project where infastructure is deployed"
}

variable "region" {
  type        = string
  description = "The location of where infastructure will be deployed"
}

variable "zone" {
  type        = string
  description = "The zone within the region where infastructure is deployed"
}

variable "k8s-version" {
  type        = string
  description = "kubernetes release version"
}

variable "cluster-tags" {
  description = "The resource tags for the cluster."
  type        = map(string)
}

#### Networking variables ###
############################# 
variable "vpc-name" {
  type        = string
  description = "The vpc name needed for creation of the nat, router, database, and private cluster"
}

variable "vpc-subnet-name" {
  type        = string
  description = "The vpc subnet name needed for creation of the nat, router, database, and private cluster"
}

variable "vpc-cidr" {
  type        = string
  description = "The ip and cidr for the vpc that is created"
}

variable "master-private-cluster-ipv4" {
  type        = string
  description = "This variable is to specify the ipv4 of the master cluster"
}