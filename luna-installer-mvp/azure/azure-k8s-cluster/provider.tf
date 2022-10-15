/*************************************************************************
Provider Initilizations 
*************************************************************************/
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>2.5"
    }
    local      = "~> 1.2"
    null       = "~> 2.1"
    random     = "~> 2.1"
    template   = "~> 2.1"
  }
}

provider "azurerm" {
  version = "~>2.5"
  subscription_id = var.subscription_id 
  client_id       = var.client_id 
  client_secret   = var.client_secret   
  tenant_id       = var.tenant_id 
  features {}
}

terraform {
  required_version = "~>0.13.0"
  backend "azurerm" {
  }
}
