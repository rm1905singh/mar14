terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.95.0"
    }
  }
}

provider "azurerm" {
  features {

  }
}

resource "azurerm_resource_group" "rgblock" {
  name     = "rms-rg"
  location = "West Europe"
}

resource "azurerm_virtual_network" "vnetblock" {
  depends_on          = [azurerm_resource_group.rgblock]
  name                = "rms-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "West Europe"
  resource_group_name = "rms-rg"
}

resource "azurerm_subnet" "sblock" {
  depends_on           = [azurerm_virtual_network.vnetblock]
  name                 = "rms-subnet"
  resource_group_name  = "rms-rg"
  virtual_network_name = "rms-vnet"
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "pipblock" {
  depends_on          = [azurerm_resource_group.rgblock]
  name                = "rms-pip"
  resource_group_name = "rms-rg"
  location            = "West Europe"
  allocation_method   = "Static"

  tags = {
    environment = "dev"
  }
}
resource "azurerm_network_interface" "nicblock" {
  depends_on          = [azurerm_subnet.sblock]
  name                = "rms-nic"
  location            = "West Europe"
  resource_group_name = "rms-rg"

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sblock.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.pipblock.id
  }
}
resource "azurerm_network_security_group" "nsgblock" {
    depends_on = [ azurerm_resource_group.rgblock ]
  name                = "rms-nsg"
  location            = "West Europe"
  resource_group_name = "rms-rg"

  security_rule {
    name                       = "test123"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "dev"
  }
}
resource "azurerm_subnet_network_security_group_association" "nsgasblock" {
    depends_on = [ azurerm_network_security_group.nsgblock ]
  subnet_id                 = azurerm_subnet.sblock.id
  network_security_group_id = azurerm_network_interface.nicblock.id
}

resource "azurerm_linux_virtual_machine" "vmblock" {
    depends_on = [ azurerm_network_interface.nicblock ]
  name                = "rms-vm"
  resource_group_name = "rms-rg"
  location            = "West Europe"
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password = "adminuser@1234"
  network_interface_ids = [azurerm_network_interface.nicblock.id ]


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}
