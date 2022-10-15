/*************************************************************************
 Cluster Networking Setup for Internal Network
*************************************************************************/

resource "azurerm_virtual_network" "vnet_cluster" {
  name                = "${local.virtual-network-name-cluster}" 
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  address_space       = [var.secondary-vpc-cidr] 

  tags = var.cluster-tags
}  

resource "azurerm_subnet" "snet_cluster" {
  depends_on = [ azurerm_virtual_network.vnet_cluster ]
  name                 = "${local.subnet-name-cluster}" 
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.vnet_cluster.name
  address_prefixes     = [var.secondary-subnet-cidr]

  service_endpoints = ["Microsoft.Storage", "Microsoft.Sql"]
  enforce_private_link_endpoint_network_policies = true
}

#VNET Peering between the Installer VNET and the Cluster VNET
resource "azurerm_virtual_network_peering" "peering_bastion_cluster" {
  depends_on = [azurerm_virtual_network.vnet_cluster, azurerm_subnet.snet_cluster ]
  name                      = "luna-peering-installer-cluster" 
  resource_group_name       = data.azurerm_resource_group.main.name
  virtual_network_name      = element(split( "/", var.vpc-id), length(split( "/", var.vpc-id))-1)
  remote_virtual_network_id = azurerm_virtual_network.vnet_cluster.id
  
}

#VNET Peering between the Installer VNET and the Cluster VNET
resource "azurerm_virtual_network_peering" "peering_cluster_bastion" {
  depends_on = [ azurerm_virtual_network.vnet_cluster, azurerm_subnet.snet_cluster ]
  name                      = "luna-peering-cluster-installer" 
  resource_group_name       = data.azurerm_resource_group.main.name
  virtual_network_name      = azurerm_virtual_network.vnet_cluster.name
  remote_virtual_network_id = var.vpc-id
}




