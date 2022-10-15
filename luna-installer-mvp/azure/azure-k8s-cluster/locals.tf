/*************************************************************************
Local Variable Declarations - File is used to consolidate a consistant 
naming convention across the modules
*************************************************************************/
resource "random_string" "this" {
  length           = 16
  special          = false
  upper            = false
  number           = false
  override_special = "/@£$"
}

locals {
  customer-name                = format("luna-%s", var.customer-name)
  cluster-name                 = format("%s-k8s-00%d", local.customer-name, var.infra-version-suffix)
  windows-nodes                = format("luna%sw", var.customer-name)
  resource-group-name          = format("%s-rg-00%d", local.customer-name, var.infra-version-suffix)
  virtual-network-name         = format("luna-%s-vnet-00%d", var.customer-name, var.infra-version-suffix)
  subnet-name                  = format("luna-%s-snet-00%d", var.customer-name, var.infra-version-suffix)
  virtual-network-name-cluster = format("luna-%s-vnet-cluster", var.customer-name)
  subnet-name-cluster          = format("luna-%s-snet-cluster", var.customer-name)

#Helpful repo - https://github.com/claranet/terraform-azurerm-regions/blob/master/regions.tf
 regions = {

    "eastus"         = "East US"
    "eastus2"        = "East US 2"
    "centralus"      = "Central US"
    "westus2"        = "West US 2"
    "southcentralus" = "South Central US"
    "northeurope"    = "North Europe"
    "westeurope"     = "West Europe"

  }
}