/*************************************************************************
 Backend Variables for Remote State 
*************************************************************************/
variable "bucket" {
  type        = string
  description = "The name of the bucket where the state file will be stored. This bucket needs to be configured with the appropriate permissions to enable the service principal to get/update the statefile."
}

variable "key" {
  type        = string
  default     = "statefiles/dev-pov.tfstate"
  description = "The name of the statefile for the infrastructure."
}

variable "region" {
  type        = string
  default     = "us-east-2"
  description = "The region where the S3 bucket is located."
}

variable "dynamodb_table" {
  type        = string
  default     = null
  description = "The name of the dynamodb table that is managing the state locking for the S3 Bucket."
}