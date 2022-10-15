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
  k8s_service_account_namespace = "kube-system"
  k8s_service_account_name      = "cluster-autoscaler-aws-cluster-autoscaler-chart"
}