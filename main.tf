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
  name                = "networkfort"
  location            = var.location
  resource_group_name = azurerm_resource_group.testingresource.name
  network_interface_ids = [azurerm_network_interface.networkfort_nic.id]
  size                = "Standard_B1s"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
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

resource "azurerm_public_ip" "networkfort_tester_pip" {
  name                = "networkfortTesterPublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.testingresource.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_interface" "networkfort_tester_nic" {
  name                = "networkfortTesterNIC"
  location            = var.location
  resource_group_name = azurerm_resource_group.testingresource.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.networkfort_tester_pip.id
  }
}

resource "azurerm_network_interface_security_group_association" "networkfort_tester_nsg_association" {
  network_interface_id      = azurerm_network_interface.networkfort_tester_nic.id
  network_security_group_id = azurerm_network_security_group.networkfort_nsg.id
}

resource "azurerm_linux_virtual_machine" "networkfort_tester" {
  name                = "networkfort-tester"
  location            = var.location
  resource_group_name = azurerm_resource_group.testingresource.name
  network_interface_ids = [azurerm_network_interface.networkfort_tester_nic.id]
  size                = "Standard_B1s"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
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
      "commandToExecute": "echo '#!/bin/bash\n\nsudo apt-get install apt-transport-https\n\n# Step 1 — Installing Elasticsearch and Kibana\n\ncurl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -\n\necho \"deb https://artifacts.elastic.co/packages/7.x/apt stable main\" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list\n\n# Update package lists\nsudo apt-get update\n\n# Install ELK Stack (Elasticsearch, Logstash, Kibana)\nsudo apt-get install -y default-jre\nsudo apt-get install -y elasticsearch logstash kibana filebeat\n\n# Start ELK Stack services\nsudo service elasticsearch start\nsudo service logstash start\nsudo service kibana start\n\nsudo filebeat modules enable suricata\nsudo filebeat modules enable zeek\n\nsudo filebeat setup\n\nsudo systemctl start filebeat.service\n\n# Install Suricata\n\nadd-apt-repository ppa:oisf/suricata-stable\n\nsudo apt-get install -y suricata\n\n# Start Suricata service\nsudo service suricata start\nsudo systemctl enable suricata\n\n# Install Zeek\n\necho 'deb http://download.opensuse.org/repositories/security:/zeek/xUbuntu_20.10/ /' | sudo tee /etc/apt/sources.list.d/security:zeek.list\ncurl -fsSL https://download.opensuse.org/repositories/security:zeek/xUbuntu_20.10/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/security_zeek.gpg > /dev/null\napt update\n\nsudo apt-get install -y zeek\n\n# Start Zeek service\nsudo zeekctl deploy\nsudo zeekctl start\n\n# Add any additional configuration or setup steps as needed\n\n# End of installation script' > install.sh && chmod +x install.sh && sudo ./install.sh"
    }
SETTINGS
}
