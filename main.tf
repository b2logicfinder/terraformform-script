provider "azurerm" {
  features {}
  subscription_id = "6856ebaf-7b03-45bb-8aea-409b2782a581"
}

variable "location" {
  description = "The location/region in which to create the resources"
  default     = "East US"
}

variable "admin_username" {
  description = "The admin username for the VMs"
  default     = "user-networkfort"
}

variable "admin_password" {
  description = "The admin password for the VMs"
  default     = "AppleNetworkfort123!"
}

resource "azurerm_resource_group" "testingresource" {
  name     = "testingresource"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "networkfortVNet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.testingresource.name
}

resource "azurerm_subnet" "main" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.testingresource.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "networkfort_nsg" {
  name                = "networkfortNSG"
  location            = var.location
  resource_group_name = azurerm_resource_group.testingresource.name

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

  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTPS"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "networkfort_pip" {
  name                = "networkfortPublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.testingresource.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "networkfort_nic" {
  name                = "networkfortNIC"
  location            = var.location
  resource_group_name = azurerm_resource_group.testingresource.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.networkfort_pip.id
  }
}

resource "azurerm_linux_virtual_machine" "networkfort" {
  name                  = "networkfort"
  location              = var.location
  resource_group_name   = azurerm_resource_group.testingresource.name
  network_interface_ids = [azurerm_network_interface.networkfort_nic.id]
  size                  = "Standard_B1s"
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  disable_password_authentication = false

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

resource "azurerm_virtual_machine_extension" "networkfort_init" {
  name                 = "networkfortInitScript"
  virtual_machine_id   = azurerm_linux_virtual_machine.networkfort.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  timeouts {
    create = "30m"
  }

 settings = <<SETTINGS
    {
       "commandToExecute": "curl -o install.sh https://raw.githubusercontent.com/b2logicfinder/terraformform-script/main/install.sh && sudo chmod +x ./install.sh && sudo ./install.sh"
    }
SETTINGS
}
