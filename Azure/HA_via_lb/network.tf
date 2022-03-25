# Networking

# Retrieve Subnet data
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
