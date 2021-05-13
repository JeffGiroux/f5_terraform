provider "azurerm" {
  features {}
}

############################ Locals for Vnets ############################

locals {
  vnets = {
    hub = {
      location       = var.azureLocation
      addressSpace   = ["10.255.0.0/16"]
      subnetPrefixes = ["10.255.10.0/24", "10.255.20.0/24", "10.255.255.0/24"]
      subnetNames    = ["external", "internal", "RouteServerSubnet"]
    }
    spoke1 = {
      location       = var.azureLocation
      addressSpace   = ["10.1.0.0/16"]
      subnetPrefixes = ["10.1.10.0/24", "10.1.20.0/24", "10.1.1.0/24"]
      subnetNames    = ["external", "internal", "mgmt"]
    }
    spoke2 = {
      location       = var.azureLocation
      addressSpace   = ["10.2.0.0/16"]
      subnetPrefixes = ["10.2.10.0/24", "10.2.20.0/24", "10.2.1.0/24"]
      subnetNames    = ["external", "internal", "mgmt"]
    }
  }
}

############################ Resource Groups ############################

# Create Resource Groups
resource "azurerm_resource_group" "rg" {
  for_each = local.vnets
  name     = format("%s-rg-%s-%s", var.projectPrefix, each.key, random_id.buildSuffix.hex)
  location = each.value["location"]

  tags = {
    Name      = format("%s-rg-%s-%s", var.resourceOwner, each.key, random_id.buildSuffix.hex)
    Terraform = "true"
  }
}

############################ VNets ############################

# Create VNets
module "network" {
  for_each            = local.vnets
  source              = "Azure/vnet/azurerm"
  resource_group_name = azurerm_resource_group.rg[each.key].name
  vnet_name           = format("%s-vnet-%s-%s", var.projectPrefix, each.key, random_id.buildSuffix.hex)
  address_space       = each.value["addressSpace"]
  subnet_prefixes     = each.value["subnetPrefixes"]
  subnet_names        = each.value["subnetNames"]

  route_tables_ids = {
    external = azurerm_route_table.rt[each.key].id
    internal = azurerm_route_table.rt[each.key].id
  }

  tags = {
    Name      = format("%s-vnet-%s-%s", var.resourceOwner, each.key, random_id.buildSuffix.hex)
    Terraform = "true"
  }
}

# Retrieve Route Server Subnet Data
data "azurerm_subnet" "routeServerSubnet" {
  name                 = "RouteServerSubnet"
  virtual_network_name = module.network["hub"].vnet_name
  resource_group_name  = azurerm_resource_group.rg["hub"].name
  depends_on           = [module.network["hub"].vnet_subnets]
}

############################ Route Server and BGP Peering ############################

resource "azurerm_virtual_hub" "routeServer" {
  name                = format("%s-routeServer-%s", var.projectPrefix, random_id.buildSuffix.hex)
  resource_group_name = azurerm_resource_group.rg["hub"].name
  location            = azurerm_resource_group.rg["hub"].location
  sku                 = "Standard"
  depends_on          = [module.network["hub"].vnet_subnets]

  tags = {
    Name      = format("%s-routeServer-%s", var.resourceOwner, random_id.buildSuffix.hex)
    Terraform = "true"
  }
}

resource "azurerm_virtual_hub_ip" "routeServerIp" {
  name           = format("%s-routeServerIp-%s", var.projectPrefix, random_id.buildSuffix.hex)
  virtual_hub_id = azurerm_virtual_hub.routeServer.id
  subnet_id      = data.azurerm_subnet.routeServerSubnet.id
}

############################ VNet Peering ############################

locals {
  spokeHubPeerings = {
    spoke1 = {
    }
    spoke2 = {
    }
  }
}

# Create hub to spoke peerings
resource "azurerm_virtual_network_peering" "hubToSpoke" {
  for_each                  = local.spokeHubPeerings
  name                      = format("hub-to-%s", each.key)
  resource_group_name       = azurerm_resource_group.rg["hub"].name
  virtual_network_name      = module.network["hub"].vnet_name
  remote_virtual_network_id = module.network[each.key].vnet_id
  allow_forwarded_traffic   = true
  #allow_gateway_transit     = true
}

# Create spoke to hub peerings
resource "azurerm_virtual_network_peering" "spokeToHub" {
  for_each                  = local.spokeHubPeerings
  name                      = format("%s-to-hub", each.key)
  resource_group_name       = azurerm_resource_group.rg[each.key].name
  virtual_network_name      = module.network[each.key].vnet_name
  remote_virtual_network_id = module.network["hub"].vnet_id
  allow_forwarded_traffic   = true
  #use_remote_gateways       = true
}

############################ Route Tables ############################

# Create Route Tables
resource "azurerm_route_table" "rt" {
  for_each                      = local.vnets
  name                          = format("%s-rt-%s-%s", var.projectPrefix, each.key, random_id.buildSuffix.hex)
  location                      = azurerm_resource_group.rg[each.key].location
  resource_group_name           = azurerm_resource_group.rg[each.key].name
  disable_bgp_route_propagation = false

  tags = {
    Name      = format("%s-rt-%s-%s", var.resourceOwner, each.key, random_id.buildSuffix.hex)
    Terraform = "true"
  }
}
