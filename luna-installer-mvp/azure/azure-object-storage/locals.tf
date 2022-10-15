/*************************************************************************
Local Variable Declarations - File is used to consolidate a consistant 
naming convention across the modules
*************************************************************************/
locals {
  customer-name = format("luna-%s", var.customer-name)
  bucket-name   = format("luna%ssa00%d", var.customer-name, var.infra-version-suffix)
  container-name   = format("luna%ssa00%d-installer", var.customer-name, var.infra-version-suffix)
  resource-group-name = format("%s-rg-00%d", local.customer-name, var.infra-version-suffix)
}