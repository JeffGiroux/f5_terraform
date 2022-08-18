# Networking

############################ Subnets ############################

data "azurerm_subnet" "mgmt" {
  name                 = var.mgmtSubnet
  virtual_network_name = var.vnet_name
  resource_group_name  = var.vnet_rg
}

data "azurerm_subnet" "external" {
  name                 = var.extSubnet
  virtual_network_name = var.vnet_name
  resource_group_name  = var.vnet_rg
}

data "azurerm_subnet" "internal" {
  name                 = var.intSubnet
  virtual_network_name = var.vnet_name
  resource_group_name  = var.vnet_rg
}

############################ Security Groups ############################

data "azurerm_network_security_group" "mgmt" {
  name                = var.mgmtNsg
  resource_group_name = var.vnet_rg
}

data "azurerm_network_security_group" "external" {
  name                = var.extNsg
  resource_group_name = var.vnet_rg
}

data "azurerm_network_security_group" "internal" {
  name                = var.intNsg
  resource_group_name = var.vnet_rg
}
