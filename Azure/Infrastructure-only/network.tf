# Networking

# Create a Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.projectPrefix}-network"
  address_space       = [var.vnet_cidr]
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

# Create Management Subnet
resource "azurerm_subnet" "mgmt" {
  name                 = "mgmt"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [var.mgmt_address_prefix]
}

# Create External Subnet
resource "azurerm_subnet" "external" {
  name                 = "external"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [var.ext_address_prefix]
}

# Create Internal Subnet
resource "azurerm_subnet" "internal" {
  name                 = "internal"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [var.int_address_prefix]
}

# Create Network Security Group and rules
resource "azurerm_network_security_group" "mgmt" {
  name                = "${var.projectPrefix}-mgmt-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "allow_SSH"
    description                = "Allow SSH access"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.adminSrcAddr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_HTTPS"
    description                = "Allow HTTPS access"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.adminSrcAddr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_APP_HTTPS"
    description                = "Allow HTTPS access"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8443"
    source_address_prefix      = var.adminSrcAddr
    destination_address_prefix = "*"
  }

  tags = {
    owner = var.owner
  }
}

resource "azurerm_network_security_group" "external" {
  name                = "${var.projectPrefix}-ext-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "allow_HTTP"
    description                = "Allow HTTP access"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_HTTPS"
    description                = "Allow HTTPS access"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    owner = var.owner
  }
}

# Associate network security groups with subnets
resource "azurerm_subnet_network_security_group_association" "mgmt" {
  subnet_id                 = azurerm_subnet.mgmt.id
  network_security_group_id = azurerm_network_security_group.mgmt.id
}

resource "azurerm_subnet_network_security_group_association" "external" {
  subnet_id                 = azurerm_subnet.external.id
  network_security_group_id = azurerm_network_security_group.external.id
}
