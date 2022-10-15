/*************************************************************************
 Object Storage Output File 
*************************************************************************/
output "resource-group" {
  value = data.azurerm_resource_group.main.name
}

output "resource-group-location" {
  value = data.azurerm_resource_group.main.location
}

output "storage-account-name" {
  value = azurerm_storage_account.luna-storage-account.name
}

output "container-name" {
  value = azurerm_storage_container.luna-container.name
}