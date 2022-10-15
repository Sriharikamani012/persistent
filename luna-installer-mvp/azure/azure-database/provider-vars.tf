/*************************************************************************
 Backend Variables for Remote State 
*************************************************************************/
variable "subscription_id" {
  type        = string
  description = "The Azure Subscription ID."
}

variable "client_id" {
  type        = string
  description = "The service principal client id. Will be parsed from the Azure credentials file."
}

variable "client_secret" {
  type        = string
  description = "The service principal client secret. Will be parsed from the Azure credentials file."
}

variable "tenant_id" {
  type        = string
  description = "The Azure Tenant ID, can be located in Active Directory. Will be parsed from the Azure credentials file."
}

