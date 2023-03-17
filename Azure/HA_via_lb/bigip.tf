# BIG-IP Cluster

############################ Locals ############################

locals {
  # Retrieve all BIG-IP secondary IPs
  vm01_ext_ips = {
    0 = {
      ip = element(flatten(module.bigip.private_addresses["public_private"]["private_ips"][0]), 0)
    }
    1 = {
      ip = element(flatten(module.bigip.private_addresses["public_private"]["private_ips"][0]), 1)
    }
  }
  vm02_ext_ips = {
    0 = {
      ip = element(flatten(module.bigip2.private_addresses["public_private"]["private_ips"][0]), 0)
    }
    1 = {
      ip = element(flatten(module.bigip2.private_addresses["public_private"]["private_ips"][0]), 1)
    }
  }
  # Determine BIG-IP secondary IPs to be used for VIP
  vm01_vip_ips = {
    app1 = {
      ip = module.bigip.private_addresses["public_private"]["private_ip"][0] != local.vm01_ext_ips.0.ip ? local.vm01_ext_ips.0.ip : local.vm01_ext_ips.1.ip
    }
  }
  vm02_vip_ips = {
    app1 = {
      ip = module.bigip2.private_addresses["public_private"]["private_ip"][0] != local.vm02_ext_ips.0.ip ? local.vm02_ext_ips.0.ip : local.vm02_ext_ips.1.ip
    }
  }
  # Custom tags
  tags = {
    Owner = var.resourceOwner
  }
}

############################ Onboard Scripts ############################

# Setup Onboarding scripts
locals {
  f5_onboard1 = templatefile("${path.module}/f5_onboard.tmpl", {
    regKey                     = var.license1
    f5_username                = var.f5_username
    f5_password                = var.az_keyvault_authentication ? "" : var.f5_password
    az_keyvault_authentication = var.az_keyvault_authentication
    vault_url                  = var.az_keyvault_authentication ? data.azurerm_key_vault.main[0].vault_uri : ""
    keyvault_secret            = var.az_keyvault_authentication ? var.keyvault_secret : ""
    ssh_keypair                = file(var.ssh_key)
    INIT_URL                   = var.INIT_URL
    DO_URL                     = var.DO_URL
    AS3_URL                    = var.AS3_URL
    TS_URL                     = var.TS_URL
    FAST_URL                   = var.FAST_URL
    DO_VER                     = split("/", var.DO_URL)[7]
    AS3_VER                    = split("/", var.AS3_URL)[7]
    TS_VER                     = split("/", var.TS_URL)[7]
    FAST_VER                   = split("/", var.FAST_URL)[7]
    dns_server                 = var.dns_server
    dns_suffix                 = var.dns_suffix
    ntp_server                 = var.ntp_server
    timezone                   = var.timezone
    law_id                     = azurerm_log_analytics_workspace.main.workspace_id
    law_primkey                = azurerm_log_analytics_workspace.main.primary_shared_key
    bigIqLicenseType           = var.bigIqLicenseType
    bigIqHost                  = var.bigIqHost
    bigIqPassword              = var.bigIqPassword
    bigIqUsername              = var.bigIqUsername
    bigIqLicensePool           = var.bigIqLicensePool
    bigIqSkuKeyword1           = var.bigIqSkuKeyword1
    bigIqSkuKeyword2           = var.bigIqSkuKeyword2
    bigIqUnitOfMeasure         = var.bigIqUnitOfMeasure
    bigIqHypervisor            = var.bigIqHypervisor
    # cluster info
    host1             = module.bigip.private_addresses["mgmt_private"]["private_ip"][0]
    host2             = module.bigip2.private_addresses["mgmt_private"]["private_ip"][0]
    remote_selfip_ext = module.bigip2.private_addresses["public_private"]["private_ip"][0]
  })
  f5_onboard2 = templatefile("${path.module}/f5_onboard.tmpl", {
    regKey                     = var.license2
    f5_username                = var.f5_username
    f5_password                = var.az_keyvault_authentication ? "" : var.f5_password
    az_keyvault_authentication = var.az_keyvault_authentication
    vault_url                  = var.az_keyvault_authentication ? data.azurerm_key_vault.main[0].vault_uri : ""
    keyvault_secret            = var.az_keyvault_authentication ? var.keyvault_secret : ""
    ssh_keypair                = file(var.ssh_key)
    INIT_URL                   = var.INIT_URL
    DO_URL                     = var.DO_URL
    AS3_URL                    = var.AS3_URL
    TS_URL                     = var.TS_URL
    FAST_URL                   = var.FAST_URL
    DO_VER                     = split("/", var.DO_URL)[7]
    AS3_VER                    = split("/", var.AS3_URL)[7]
    TS_VER                     = split("/", var.TS_URL)[7]
    FAST_VER                   = split("/", var.FAST_URL)[7]
    dns_server                 = var.dns_server
    dns_suffix                 = var.dns_suffix
    ntp_server                 = var.ntp_server
    timezone                   = var.timezone
    law_id                     = azurerm_log_analytics_workspace.main.workspace_id
    law_primkey                = azurerm_log_analytics_workspace.main.primary_shared_key
    bigIqLicenseType           = var.bigIqLicenseType
    bigIqHost                  = var.bigIqHost
    bigIqPassword              = var.bigIqPassword
    bigIqUsername              = var.bigIqUsername
    bigIqLicensePool           = var.bigIqLicensePool
    bigIqSkuKeyword1           = var.bigIqSkuKeyword1
    bigIqSkuKeyword2           = var.bigIqSkuKeyword2
    bigIqUnitOfMeasure         = var.bigIqUnitOfMeasure
    bigIqHypervisor            = var.bigIqHypervisor
    # cluster info
    host1             = module.bigip.private_addresses["mgmt_private"]["private_ip"][0]
    host2             = module.bigip2.private_addresses["mgmt_private"]["private_ip"][0]
    remote_selfip_ext = module.bigip.private_addresses["public_private"]["private_ip"][0]
  })
}

############################ Compute ############################

# Create F5 BIG-IP VMs
module "bigip" {
  source                     = "F5Networks/bigip-module/azure"
  version                    = "1.2.8"
  prefix                     = var.projectPrefix
  vm_name                    = var.vm_name == "" ? format("%s-bigip1-%s", var.projectPrefix, random_id.buildSuffix.hex) : var.vm_name
  resource_group_name        = azurerm_resource_group.main.name
  f5_instance_type           = var.instance_type
  f5_image_name              = var.image_name
  f5_product_name            = var.product
  f5_version                 = var.bigip_version
  f5_username                = var.f5_username
  f5_ssh_publickey           = file(var.ssh_key)
  mgmt_subnet_ids            = [{ "subnet_id" = data.azurerm_subnet.mgmt.id, "public_ip" = true, "private_ip_primary" = "" }]
  mgmt_securitygroup_ids     = [data.azurerm_network_security_group.mgmt.id]
  external_subnet_ids        = [{ "subnet_id" = data.azurerm_subnet.external.id, "public_ip" = true, "private_ip_primary" = "", "private_ip_secondary" = "" }]
  external_securitygroup_ids = [data.azurerm_network_security_group.external.id]
  internal_subnet_ids        = [{ "subnet_id" = data.azurerm_subnet.internal.id, "public_ip" = false, "private_ip_primary" = "" }]
  internal_securitygroup_ids = [data.azurerm_network_security_group.internal.id]
  availability_zone          = var.availability_zone
  custom_user_data           = local.f5_onboard1
  sleep_time                 = "30s"
  tags                       = local.tags
  az_keyvault_authentication = var.az_keyvault_authentication
  azure_secret_rg            = var.az_keyvault_authentication ? var.keyvault_rg : ""
  azure_keyvault_name        = var.az_keyvault_authentication ? var.keyvault_name : ""
  azure_keyvault_secret_name = var.az_keyvault_authentication ? var.keyvault_secret : ""
  user_identity              = var.az_keyvault_authentication ? data.azurerm_user_assigned_identity.main[0].id : null
}

module "bigip2" {
  source                     = "F5Networks/bigip-module/azure"
  version                    = "1.2.8"
  prefix                     = var.projectPrefix
  vm_name                    = var.vm2_name == "" ? format("%s-bigip2-%s", var.projectPrefix, random_id.buildSuffix.hex) : var.vm2_name
  resource_group_name        = azurerm_resource_group.main.name
  f5_instance_type           = var.instance_type
  f5_image_name              = var.image_name
  f5_product_name            = var.product
  f5_version                 = var.bigip_version
  f5_username                = var.f5_username
  f5_ssh_publickey           = file(var.ssh_key)
  mgmt_subnet_ids            = [{ "subnet_id" = data.azurerm_subnet.mgmt.id, "public_ip" = true, "private_ip_primary" = "" }]
  mgmt_securitygroup_ids     = [data.azurerm_network_security_group.mgmt.id]
  external_subnet_ids        = [{ "subnet_id" = data.azurerm_subnet.external.id, "public_ip" = true, "private_ip_primary" = "", "private_ip_secondary" = "" }]
  external_securitygroup_ids = [data.azurerm_network_security_group.external.id]
  internal_subnet_ids        = [{ "subnet_id" = data.azurerm_subnet.internal.id, "public_ip" = false, "private_ip_primary" = "" }]
  internal_securitygroup_ids = [data.azurerm_network_security_group.internal.id]
  availability_zone          = var.availability_zone2
  custom_user_data           = local.f5_onboard2
  sleep_time                 = "30s"
  tags                       = local.tags
  az_keyvault_authentication = var.az_keyvault_authentication
  azure_secret_rg            = var.az_keyvault_authentication ? var.keyvault_rg : ""
  azure_keyvault_name        = var.az_keyvault_authentication ? var.keyvault_name : ""
  azure_keyvault_secret_name = var.az_keyvault_authentication ? var.keyvault_secret : ""
  user_identity              = var.az_keyvault_authentication ? data.azurerm_user_assigned_identity.main[0].id : null
}

############################ ALB Backend Pool ############################

# Note: JeffGiroux (REMOVE LATER)
#       https://github.com/F5Networks/terraform-azure-bigip-module/issues/29
#
#       BIG-IP module currently does NOT export network interface ID.
#       As a workaround, use the BIG-IP device ID to parse the name and
#       use that to query the data azurerm_network_interface.
#       Once output in module is fixed, data resource can be deleted.

# Retrieve NIC Info
data "azurerm_network_interface" "bigip-ext" {
  name                = format("%s-ext-nic-public-0", element(split("-f5vm01", element(split("/", module.bigip.bigip_instance_ids), 8)), 0))
  resource_group_name = azurerm_resource_group.main.name
}
data "azurerm_network_interface" "bigip2-ext" {
  name                = format("%s-ext-nic-public-0", element(split("-f5vm01", element(split("/", module.bigip2.bigip_instance_ids), 8)), 0))
  resource_group_name = azurerm_resource_group.main.name
}

# Associate the BIG-IP NIC to the ALB backend pool
resource "azurerm_network_interface_backend_address_pool_association" "f5vm01" {
  network_interface_id    = data.azurerm_network_interface.bigip-ext.id
  ip_configuration_name   = format("%s-secondary-ext-public-ip-0", element(split("-f5vm01", element(split("/", module.bigip.bigip_instance_ids), 8)), 0))
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
}

resource "azurerm_network_interface_backend_address_pool_association" "f5vm02" {
  network_interface_id    = data.azurerm_network_interface.bigip2-ext.id
  ip_configuration_name   = format("%s-secondary-ext-public-ip-0", element(split("-f5vm01", element(split("/", module.bigip2.bigip_instance_ids), 8)), 0))
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
}
