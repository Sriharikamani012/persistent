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
  database-name        = format("luna%spostgres%s", var.customer-name, random_string.this.id)
}
