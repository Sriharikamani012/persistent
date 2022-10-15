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
  customer-name        = format("luna-%s", var.customer-name)
  database-name         = format("%s-psql-00%d", local.customer-name, var.infra-version-suffix)
  windows-nodes        = format("luna%sw", var.customer-name)
  resource-group-name  = format("%s-rg-00%d", local.customer-name, var.infra-version-suffix)
  virtual-network-name = format("luna-%s-vnet-cluster", var.customer-name) #TODO Fix naming convention
  subnet-name          = format("luna-%s-snet-cluster", var.customer-name)
}