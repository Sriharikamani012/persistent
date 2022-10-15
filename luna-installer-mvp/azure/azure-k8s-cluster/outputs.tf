/*************************************************************************
 Kubernetes Cluster Output File 
*************************************************************************/
output "vpc_id" {
  value = azurerm_virtual_network.vnet_cluster.id
}

output "password" {
  value = random_password.password.result
}

output "resource_group_name" {
  value = data.azurerm_resource_group.main.name
}

output "aks_id" {
  value = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  value = "${local.cluster-name}-aks"
}

output "clusterversion" {
  value = data.azurerm_kubernetes_service_versions.current.latest_version 
}