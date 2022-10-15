/*************************************************************************
 AWS VPC Variables
*************************************************************************/
variable "vpc-id" {
  type        = string
  description = "ID of the VPC that has been created."
}

variable "vpc-cidr" {
  type        = string
  description = "The specified cidr range for the VPC that will be created. "
}

variable "privateSubnet1" {
  type        = string
  description = "List of CIDR Ranges for the private subnets within the VPC."
}

variable "publicSubnet1" {
  type        = string
  description = "List of CIDR Ranges for the public subnets within the VPC."
}

variable "privateSubnet2" {
  type        = string
  description = "List of CIDR Ranges for the private subnets within the VPC."
}

variable "publicSubnet2" {
  type        = string
  description = "List of CIDR Ranges for the public subnets within the VPC."
}

variable "privateSubnet3" {
  type        = string
  description = "List of CIDR Ranges for the private subnets within the VPC."
}

variable "publicSubnet3" {
  type        = string
  description = "List of CIDR Ranges for the public subnets within the VPC."
}

variable "enable-s3-endpoint" {
  description = "Should be true if you want to provision an S3 endpoint to the VPC"
  type        = bool
  default     = true
} 
