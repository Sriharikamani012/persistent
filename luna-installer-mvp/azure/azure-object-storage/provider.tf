/*************************************************************************
Provider Initilizations 
*************************************************************************/
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.4.0"
    }
    local      = "~> 1.2"
    null       = "~> 2.1"
    random     = "~> 2.1"
    template   = "~> 2.1"
  }
}

provider "azurerm" {
  version = "=2.4.0"
  subscription_id = var.subscription_id #User Input
  client_id       = var.client_id #Credential Input
  client_secret   = var.client_secret   #Credential Input
  tenant_id       = var.tenant_id #Credential Input

  features {}
}

terraform {
  required_version = "~>0.13.0"
}
