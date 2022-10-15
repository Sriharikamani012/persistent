/*************************************************************************
Storage Account Deployment 
*************************************************************************/
data "azurerm_resource_group" "main" {
  name       = local.resource-group-name
}

resource "azurerm_storage_account" "luna-storage-account" {
  name                     = local.bucket-name 
  resource_group_name      = local.resource-group-name

  location                 = data.azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

#   TODO Customize Networking rules 
#   network_rules {
#     default_action             = "Deny"
#     ip_rules                   = ["100.0.0.1"]
#     virtual_network_subnet_ids = [azurerm_subnet.example.id]
#   }

  tags = var.cluster-tags
}

resource "azurerm_storage_container" "luna-container" {

  name                  = "${local.container-name}"  #TODO Change this to INstaller -installer
  storage_account_name  = azurerm_storage_account.luna-storage-account.name
  container_access_type = "private"

  #TODO Put TAGS TO NOT DELETE
}