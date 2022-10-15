#Documentation Used to write this terraform 
#https://docs.microsoft.com/en-us/azure/developer/terraform/create-linux-virtual-machine-with-infrastructure



resource "azurerm_resource_group" "luna-rg" {
  name     = local.resource-group-name
  location = var.region #TODO Convert this into a map to accept various regions
}

data "azurerm_resource_group" "main" {
  depends_on = [azurerm_resource_group.luna-rg]
  name       = "${local.resource-group-name}"
}

resource "azurerm_virtual_network" "vnet_bastion" {
  name                = "${local.virtual-network-name}-installer" 
  location            = data.azurerm_resource_group.main.location
  resource_group_name = "${local.resource-group-name}"
  address_space       = ["10.0.0.0/16"] #TODO Input
}

resource "azurerm_subnet" "snet_bastion_vm" {
  name                 = "${local.subnet-name}-installer" 
  resource_group_name  = "${local.resource-group-name}"
  virtual_network_name = azurerm_virtual_network.vnet_bastion.name
  address_prefixes     = ["10.0.0.0/24"]
}

/*

resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP"
    location                     = "eastus"
    resource_group_name          = local.resource-group-name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = local.resource-group-name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_network_interface" "myterraformnic" {
    name                        = "myNIC"
    location                    = "eastus"
    resource_group_name         = local.resource-group-name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = azurerm_subnet.snet_bastion_vm.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
    network_interface_id      = azurerm_network_interface.myterraformnic.id
    network_security_group_id = azurerm_network_security_group.myterraformnsg.id
}

resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}

output "tls_private_key" { value = tls_private_key.example_ssh.private_key_pem }

resource "azurerm_linux_virtual_machine" "myterraformvm" {
    name                  = "Luna-Installer"
    location              = "eastus"
    resource_group_name   = local.resource-group-name
    network_interface_ids = [azurerm_network_interface.myterraformnic.id]
    size                  = "Standard_DS1_v2"

    os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }

    computer_name  = "myvm"
    admin_username = "ubuntu"
    disable_password_authentication = true

    admin_ssh_key {
        username       = "azureuser"
        public_key     = tls_private_key.example_ssh.public_key_openssh
    }

    tags = {
        environment = "Terraform Demo"
    }
}

*/