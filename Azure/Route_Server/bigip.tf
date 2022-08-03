############################ Locals ############################

# Setup Onboarding scripts
locals {
  f5_onboard1 = templatefile("${path.module}/f5_onboard.tmpl", {
    f5_username        = var.f5_username
    f5_password        = var.f5_password
    ssh_keypair        = file(var.f5_ssh_publickey)
    INIT_URL           = var.INIT_URL
    DO_URL             = var.DO_URL
    AS3_URL            = var.AS3_URL
    TS_URL             = var.TS_URL
    FAST_URL           = var.FAST_URL
    DO_VER             = split("/", var.DO_URL)[7]
    AS3_VER            = split("/", var.AS3_URL)[7]
    TS_VER             = split("/", var.TS_URL)[7]
    FAST_VER           = split("/", var.FAST_URL)[7]
    dns_server         = var.dns_server
    ntp_server         = var.ntp_server
    timezone           = var.timezone
    bigIqLicenseType   = var.bigIqLicenseType
    bigIqHost          = var.bigIqHost
    bigIqPassword      = var.bigIqPassword
    bigIqUsername      = var.bigIqUsername
    bigIqLicensePool   = var.bigIqLicensePool
    bigIqSkuKeyword1   = var.bigIqSkuKeyword1
    bigIqSkuKeyword2   = var.bigIqSkuKeyword2
    bigIqUnitOfMeasure = var.bigIqUnitOfMeasure
    bigIqHypervisor    = var.bigIqHypervisor
  })
}



# Create F5 BIG-IP VMs
module "bigip" {
  count                      = var.instanceCountBigIp
  source                     = "github.com/F5Networks/terraform-azure-bigip-module"
  prefix                     = var.prefix
  resource_group_name        = azurerm_resource_group.rg["hub"].name
  mgmt_subnet_ids            = [{ "subnet_id" = data.azurerm_subnet.mgmtSubnetHub.id, "public_ip" = true, "private_ip_primary" = "" }]
  mgmt_securitygroup_ids     = [module.nsg-mgmt["hub"].network_security_group_id]
  external_subnet_ids        = [{ "subnet_id" = data.azurerm_subnet.externalSubnetHub.id, "public_ip" = true, "private_ip_primary" = "", "private_ip_secondary" = "" }]
  external_securitygroup_ids = [module.nsg-external["hub"].network_security_group_id]
  internal_subnet_ids        = [{ "subnet_id" = data.azurerm_subnet.internalSubnetHub.id, "public_ip" = false, "private_ip_primary" = "" }]
  internal_securitygroup_ids = [module.nsg-internal["hub"].network_security_group_id]
  availability_zone          = var.availability_zone
  f5_ssh_publickey           = file(var.f5_ssh_publickey)
  f5_username                = var.f5_username
  f5_password                = var.f5_password
  f5_instance_type           = var.f5_instance_type
  f5_version                 = var.f5_version
  custom_user_data           = local.f5_onboard1
}
