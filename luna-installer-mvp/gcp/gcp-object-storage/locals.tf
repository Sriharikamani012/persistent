/*************************************************************************
Local Variable Declarations - File is used to consolidate a consistant
naming convention across the modules
*************************************************************************/
resource "random_string" "this" {
  length           = 16
  special          = false
  upper            = false
  override_special = "/@£$"
}

locals {
  customer-name = format("luna-%s", var.customer-name)
  bucket-name   = format("%s-gcp-bucket-%s-00%d", local.customer-name, random_string.this.id, var.infra-version-suffix)
}
