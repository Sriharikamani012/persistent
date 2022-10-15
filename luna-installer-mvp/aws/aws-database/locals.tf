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
  customer-name = format("luna-%s", var.customer-name)
  cluster-name  = format("%s-k8s-00%d-eks", local.customer-name, var.infra-version-suffix)
  database-name = format("luna%srdspostgres%s", var.customer-name, random_string.this.id)
  security-group-name = format("%s-k8s-00%d-eks-eks_cluster_sg", local.customer-name, var.infra-version-suffix)
}