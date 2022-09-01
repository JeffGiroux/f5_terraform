# BIG-IP

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
  # Determine BIG-IP secondary IPs to be used for VIP
  vm01_vip_ips = {
    app1 = {
      ip = module.bigip.private_addresses["public_private"]["private_ip"][0] != local.vm01_ext_ips.0.ip ? local.vm01_ext_ips.0.ip : local.vm01_ext_ips.1.ip
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
    f5_password                = var.f5_password
    az_keyvault_authentication = var.az_keyvault_authentication
    vault_url                  = var.az_keyvault_authentication ? var.keyvault_url : ""
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
    ntp_server                 = var.ntp_server
    timezone                   = var.timezone
    law_id                     = azurerm_log_analytics_workspace.law.workspace_id
    law_primkey                = azurerm_log_analytics_workspace.law.primary_shared_key
    bigIqLicenseType           = var.bigIqLicenseType
    bigIqHost                  = var.bigIqHost
    bigIqPassword              = var.bigIqPassword
    bigIqUsername              = var.bigIqUsername
    bigIqLicensePool           = var.bigIqLicensePool
    bigIqSkuKeyword1           = var.bigIqSkuKeyword1
    bigIqSkuKeyword2           = var.bigIqSkuKeyword2
    bigIqUnitOfMeasure         = var.bigIqUnitOfMeasure
    bigIqHypervisor            = var.bigIqHypervisor
  })
}

############################ Compute ############################

# Create F5 BIG-IP VMs
module "bigip" {
  source                     = "github.com/F5Networks/terraform-azure-bigip-module"
  prefix                     = var.projectPrefix
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
  #az_user_identity           = var.user_identity
}
