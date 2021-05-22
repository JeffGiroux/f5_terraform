module "bigip" {
  count                      = var.instanceCountBigIp
  source                     = "github.com/JeffGiroux/terraform-azure-bigip-module"
  prefix                     = var.projectPrefix
  resource_group_name        = azurerm_resource_group.rg["hub"].name
  mgmt_subnet_ids            = [{ "subnet_id" = data.azurerm_subnet.mgmtSubnetHub.id, "public_ip" = true, "private_ip_primary" = "" }]
  mgmt_securitygroup_ids     = [module.nsg-mgmt["hub"].network_security_group_id]
  external_subnet_ids        = [{ "subnet_id" = data.azurerm_subnet.externalSubnetHub.id, "public_ip" = true, "private_ip_primary" = "", "private_ip_secondary" = "" }]
  external_securitygroup_ids = [module.nsg-external["hub"].network_security_group_id]
  internal_subnet_ids        = [{ "subnet_id" = data.azurerm_subnet.internalSubnetHub.id, "public_ip" = false, "private_ip_primary" = "" }]
  internal_securitygroup_ids = [module.nsg-internal["hub"].network_security_group_id]
  availabilityZones          = var.availabilityZones
  f5_ssh_publickey           = var.keyName
  f5_username                = var.f5UserName
  f5_version                 = var.f5Version
  script_name                = "f5_onboard_bgp"
}

resource "null_resource" "clusterDO" {
  count = var.instanceCountBigIp

  provisioner "local-exec" {
    command = "cat > DO_3nic-instance${count.index}.json <<EOL\n ${module.bigip[count.index].onboard_do}\nEOL"
  }
  provisioner "local-exec" {
    when    = destroy
    command = "rm -rf DO_3nic-instance${count.index}.json"
  }

  depends_on = [module.bigip.onboard_do]
}
