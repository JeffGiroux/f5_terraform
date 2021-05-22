provider "azurerm" {
  features {}
}

############################ Locals ############################

locals {
  vnets = {
    hub = {
      location       = var.azureLocation
      addressSpace   = ["10.255.0.0/16"]
      subnetPrefixes = ["10.255.1.0/24", "10.255.10.0/24", "10.255.20.0/24", "10.255.255.0/24"]
      subnetNames    = ["mgmt", "external", "internal", "RouteServerSubnet"]
    }
    spoke1 = {
      location       = var.azureLocation
      addressSpace   = ["10.1.0.0/16"]
      subnetPrefixes = ["10.1.1.0/24", "10.1.10.0/24", "10.1.20.0/24"]
      subnetNames    = ["mgmt", "external", "internal"]
    }
    spoke2 = {
      location       = var.azureLocation
      addressSpace   = ["10.2.0.0/16"]
      subnetPrefixes = ["10.2.1.0/24", "10.2.10.0/24", "10.2.20.0/24"]
      subnetNames    = ["mgmt", "external", "internal"]
    }
  }

  spokeHubPeerings = {
    spoke1 = {
    }
    spoke2 = {
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

############################ Network Security Groups ############################

# Create Mgmt NSG
module "nsg-mgmt" {
  for_each              = local.vnets
  source                = "Azure/network-security-group/azurerm"
  resource_group_name   = azurerm_resource_group.rg[each.key].name
  location              = azurerm_resource_group.rg[each.key].location
  security_group_name   = format("%s-nsg-mgmt-%s-%s", var.projectPrefix, each.key, random_id.buildSuffix.hex)
  source_address_prefix = [var.adminSrcAddr]

  predefined_rules = [
    {
      name     = "HTTP"
      priority = "100"
    },
    {
      name     = "HTTPS"
      priority = "110"
    },
    {
      name     = "SSH"
      priority = "120"
    }
  ]

  tags = {
    Name      = format("%s-nsg-mgmt-%s-%s", var.resourceOwner, each.key, random_id.buildSuffix.hex)
    Terraform = "true"
  }
}

# Create External NSG
module "nsg-external" {
  for_each              = local.vnets
  source                = "Azure/network-security-group/azurerm"
  resource_group_name   = azurerm_resource_group.rg[each.key].name
  location              = azurerm_resource_group.rg[each.key].location
  security_group_name   = format("%s-nsg-external-%s-%s", var.projectPrefix, each.key, random_id.buildSuffix.hex)
  source_address_prefix = ["*"]

  predefined_rules = [
    {
      name     = "HTTP"
      priority = "100"
    },
    {
      name     = "HTTPS"
      priority = "110"
    }
  ]

  tags = {
    Name      = format("%s-nsg-external-%s-%s", var.resourceOwner, each.key, random_id.buildSuffix.hex)
    Terraform = "true"
  }
}

# Create Internal NSG
module "nsg-internal" {
  for_each            = local.vnets
  source              = "Azure/network-security-group/azurerm"
  resource_group_name = azurerm_resource_group.rg[each.key].name
  location            = azurerm_resource_group.rg[each.key].location
  security_group_name = format("%s-nsg-internal-%s-%s", var.projectPrefix, each.key, random_id.buildSuffix.hex)

  tags = {
    Name      = format("%s-nsg-internal-%s-%s", var.resourceOwner, each.key, random_id.buildSuffix.hex)
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

  nsg_ids = {
    external = module.nsg-external[each.key].network_security_group_id
    mgmt     = module.nsg-mgmt[each.key].network_security_group_id
  }

  route_tables_ids = {
    external = azurerm_route_table.rt[each.key].id
    internal = azurerm_route_table.rt[each.key].id
  }

  tags = {
    Name      = format("%s-vnet-%s-%s", var.resourceOwner, each.key, random_id.buildSuffix.hex)
    Terraform = "true"
  }
}

# Retrieve Hub Subnet Data
data "azurerm_subnet" "mgmtSubnetHub" {
  name                 = "mgmt"
  virtual_network_name = module.network["hub"].vnet_name
  resource_group_name  = azurerm_resource_group.rg["hub"].name
  depends_on           = [module.network["hub"].vnet_subnets]
}

data "azurerm_subnet" "externalSubnetHub" {
  name                 = "external"
  virtual_network_name = module.network["hub"].vnet_name
  resource_group_name  = azurerm_resource_group.rg["hub"].name
  depends_on           = [module.network["hub"].vnet_subnets]
}

data "azurerm_subnet" "internalSubnetHub" {
  name                 = "internal"
  virtual_network_name = module.network["hub"].vnet_name
  resource_group_name  = azurerm_resource_group.rg["hub"].name
  depends_on           = [module.network["hub"].vnet_subnets]
}

data "azurerm_subnet" "routeServerSubnetHub" {
  name                 = "RouteServerSubnet"
  virtual_network_name = module.network["hub"].vnet_name
  resource_group_name  = azurerm_resource_group.rg["hub"].name
  depends_on           = [module.network["hub"].vnet_subnets]
}

############################ VNet Peering ############################

# Create hub to spoke peerings
resource "azurerm_virtual_network_peering" "hubToSpoke" {
  for_each                  = local.spokeHubPeerings
  name                      = format("hub-to-%s", each.key)
  resource_group_name       = azurerm_resource_group.rg["hub"].name
  virtual_network_name      = module.network["hub"].vnet_name
  remote_virtual_network_id = module.network[each.key].vnet_id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
  depends_on                = [azurerm_virtual_hub_bgp_connection.bigip]
}

# Create spoke to hub peerings
resource "azurerm_virtual_network_peering" "spokeToHub" {
  for_each                  = local.spokeHubPeerings
  name                      = format("%s-to-hub", each.key)
  resource_group_name       = azurerm_resource_group.rg[each.key].name
  virtual_network_name      = module.network[each.key].vnet_name
  remote_virtual_network_id = module.network["hub"].vnet_id
  allow_forwarded_traffic   = true
  use_remote_gateways       = true
  depends_on                = [azurerm_virtual_hub_bgp_connection.bigip]
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
  subnet_id      = data.azurerm_subnet.routeServerSubnetHub.id
}

resource "azurerm_virtual_hub_bgp_connection" "bigip" {
  count          = var.instanceCountBigIp
  name           = "bigip-${count.index}"
  virtual_hub_id = azurerm_virtual_hub.routeServer.id
  peer_asn       = 65530
  peer_ip        = element(flatten(module.bigip.*.private_addresses[count.index]), 0)
  depends_on     = [azurerm_virtual_hub_ip.routeServerIp]
}

############################ VM for Client ############################

module "client" {
  source              = "Azure/compute/azurerm"
  resource_group_name = azurerm_resource_group.rg["spoke1"].name
  vm_hostname         = "client"
  vm_os_publisher     = "Canonical"
  vm_os_offer         = "0001-com-ubuntu-server-focal"
  vm_os_sku           = "20_04-lts"
  vnet_subnet_id      = module.network["spoke1"].vnet_subnets[0]
  ssh_key             = var.keyName
  remote_port         = "22"

  tags = {
    Name      = format("%s-client-%s", var.resourceOwner, random_id.buildSuffix.hex)
    Terraform = "true"
  }
}

############################ VM for App ############################

# App Onboarding script
data "local_file" "appOnboard" {
  filename = "${path.module}/scripts/init-app.sh"
}

module "app" {
  source              = "Azure/compute/azurerm"
  resource_group_name = azurerm_resource_group.rg["spoke2"].name
  vm_hostname         = "app"
  vm_os_publisher     = "Canonical"
  vm_os_offer         = "0001-com-ubuntu-server-focal"
  vm_os_sku           = "20_04-lts"
  vnet_subnet_id      = module.network["spoke2"].vnet_subnets[2]
  ssh_key             = var.keyName
  custom_data         = data.local_file.appOnboard.content_base64

  tags = {
    Name      = format("%s-app-%s", var.resourceOwner, random_id.buildSuffix.hex)
    Terraform = "true"
  }
}
