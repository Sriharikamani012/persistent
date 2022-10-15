/*************************************************************************
 Azure - Postgres Database
*************************************************************************/

data "azurerm_resource_group" "main" {
  name       = "${local.resource-group-name}"
}

#Data Block for the subnet 
data "azurerm_subnet" "snet_cluster_vnet" {
  name                 = local.subnet-name  
  virtual_network_name = local.virtual-network-name
  resource_group_name  = data.azurerm_resource_group.main.name
}

resource "random_password" "password" {
  length           = 25
  special          = true
  override_special = "!#$%^&*()-_=+[]{}<>:?"
}

module "postgresql" {
  source = "Azure/postgresql/azurerm"
  #TODO Specify tag
  resource_group_name          = data.azurerm_resource_group.main.name
  location                     = data.azurerm_resource_group.main.location

  server_name                  = local.database-name
  sku_name                     = "GP_Gen5_2"
  storage_mb                   = 5120
  backup_retention_days        = 10
  geo_redundant_backup_enabled = true
  administrator_login          = "postgres"  
  administrator_password       = random_password.password.result
  server_version               = "11"
  ssl_enforcement_enabled      = true
  db_names                     = ["luna-database"] #TODO Update
  db_charset                   = "UTF8"
  db_collation                 = "English_United States.1252"

  vnet_rule_name_prefix = "postgresql-vnet-rule-" 
  vnet_rules = [
    { name = local.subnet-name, subnet_id = data.azurerm_subnet.snet_cluster_vnet.id }  
  ]

  tags = var.cluster-tags

  postgresql_configurations = {
    backslash_quote = "on",
  }

}

resource "azurerm_recovery_services_vault" "luna-db-recovery" {
  name                = "${local.database-name}-backup-vault"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "Standard"
  tags                = var.cluster-tags
}

resource "azurerm_backup_policy_vm" "luna-backup" {
  name                = "${local.database-name}-backup-policy"
  resource_group_name = data.azurerm_resource_group.main.name
  recovery_vault_name = "${azurerm_recovery_services_vault.luna-db-recovery.name}"

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "03:00"
  }

  retention_daily {
    count = 10
  }

  tags = var.cluster-tags
}

#Future Enhancement - Enable Advanced Threat Protection 
#Future Enhancement - Enable the user of a customer managed encryption key