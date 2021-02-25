# Networking

# Create a Virtual Network for Hub
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-hub"
  address_space       = [var.cidr]
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

# Create Management Subnet for Hub
resource "azurerm_subnet" "Mgmt" {
  name                 = "Mgmt"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [var.subnets["subnet1"]]
}

# Create External Subnet for Hub
resource "azurerm_subnet" "External" {
  name                 = "External"
  virtual_network_name = azurerm_virtual_network.main.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [var.subnets["subnet2"]]
}

# Create a Virtual Network for Spoke
resource "azurerm_virtual_network" "spoke" {
  name                = "${var.prefix}-spoke"
  address_space       = [var.app-cidr]
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

# Create App1 Subnet for Spoke
resource "azurerm_subnet" "App1" {
  name                 = "App1"
  virtual_network_name = azurerm_virtual_network.spoke.name
  resource_group_name  = azurerm_resource_group.main.name
  address_prefixes     = [var.app-subnets["subnet1"]]
}

# Create Network Peerings
resource "azurerm_virtual_network_peering" "HubToSpoke" {
  name                         = "HubToSpoke"
  resource_group_name          = azurerm_resource_group.main.name
  virtual_network_name         = azurerm_virtual_network.main.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "SpokeToHub" {
  name                         = "HubToSpoke"
  resource_group_name          = azurerm_resource_group.main.name
  virtual_network_name         = azurerm_virtual_network.spoke.name
  remote_virtual_network_id    = azurerm_virtual_network.main.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}