/*************************************************************************
 Azure - AKS Cluster Module Implementation
*************************************************************************/

data "azurerm_kubernetes_service_versions" "current" {
  location = local.regions[var.region] 
  version_prefix = tonumber(var.k8s-version)
}

data "azurerm_resource_group" "main" {
  name       = var.resourceGroup
}

resource "random_password" "password" {
  length           = 25
  special          = true
  override_special = "!#$%^&*()-_=+[]{}<>:?"
}

module "ssh-key" {
  source         = "./modules/ssh-key"
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "${local.cluster-name}-aks"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  dns_prefix          = "${local.cluster-name}-aks"
  kubernetes_version  = data.azurerm_kubernetes_service_versions.current.latest_version

  network_profile {
    network_plugin     = "azure"
    docker_bridge_cidr = "192.167.0.1/16"
    dns_service_ip     = "192.168.1.1"
    service_cidr       = "192.168.0.0/16"
  }

  default_node_pool {
    name           = "default"
    node_count     = 4
    enable_auto_scaling   = true
    max_count = 6
    min_count = 4
    vm_size        = "Standard_D3_v2"
    vnet_subnet_id = azurerm_subnet.snet_cluster.id
    availability_zones    = ["1", "2"]
  }

 service_principal {
      client_id     = var.client_id
      client_secret = var.client_secret
  }

  windows_profile {
    admin_username = "lunaclusteradmin"
    admin_password = random_password.password.result
  }

  linux_profile {
    admin_username = "lunaclusteradmin"

    ssh_key {
      key_data = module.ssh-key.public_ssh_key
    }
  }

  private_cluster_enabled = true

  addon_profile {
    aci_connector_linux {
      enabled = false 
    }

    azure_policy {
      enabled = false
    }

    http_application_routing {
      enabled = false
    }

    kube_dashboard {
      enabled = false
    }

    oms_agent {
      enabled = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id 
    }
  }
  tags = var.cluster-tags
}

# #TODO Add this back in once the Luna Helm Charts are Updated to Support Windows Worker Nodes
resource "azurerm_kubernetes_cluster_node_pool" "windows" {
  depends_on = [azurerm_kubernetes_cluster.main]
  name                  = "lunaw"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vnet_subnet_id        = azurerm_subnet.snet_cluster.id
  vm_size               = "Standard_D4_v3"
  availability_zones    = ["1", "2"]
  os_type               = "Windows"

  node_count            = 3
  enable_auto_scaling   = true
  max_count = 6
  min_count = 3

  tags                  = var.cluster-tags
 }

#Logging
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${local.cluster-name}-workspace"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.cluster-tags
}

resource "azurerm_log_analytics_solution" "main" {
  solution_name         = "ContainerInsights"
  location              = data.azurerm_resource_group.main.location
  resource_group_name   = data.azurerm_resource_group.main.name
  workspace_resource_id = azurerm_log_analytics_workspace.main.id
  workspace_name        = azurerm_log_analytics_workspace.main.name
  tags                  = var.cluster-tags

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "link_bastion_cluster" {
  name = "${local.cluster-name}-dnslink" 
  private_dns_zone_name = join(".", slice(split(".", azurerm_kubernetes_cluster.main.private_fqdn), 1, length(split(".", azurerm_kubernetes_cluster.main.private_fqdn))))
  resource_group_name   = "MC_${data.azurerm_resource_group.main.name}_${azurerm_kubernetes_cluster.main.name}_${data.azurerm_resource_group.main.location}"
  virtual_network_id    = var.vpc-id

  tags = var.cluster-tags
}

