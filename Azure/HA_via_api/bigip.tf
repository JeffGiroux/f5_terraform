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

############################ Public IPs ############################

# # Create Public IPs - mgmt
# resource "azurerm_public_ip" "vm01mgmtpip" {
#   name                = format("%s-vm01-mgmt-pip-%s", var.projectPrefix, random_id.buildSuffix.hex)
#   location            = azurerm_resource_group.main.location
#   sku                 = "Standard"
#   resource_group_name = azurerm_resource_group.main.name
#   allocation_method   = "Static"
#   tags = {
#     owner = var.resourceOwner
#   }
# }

# resource "azurerm_public_ip" "vm02mgmtpip" {
#   name                = format("%s-vm02-mgmt-pip-%s", var.projectPrefix, random_id.buildSuffix.hex)
#   location            = azurerm_resource_group.main.location
#   sku                 = "Standard"
#   resource_group_name = azurerm_resource_group.main.name
#   allocation_method   = "Static"
#   tags = {
#     owner = var.resourceOwner
#   }
# }

# # Create Public IPs - external
# resource "azurerm_public_ip" "vm01selfpip" {
#   name                = format("%s-vm01-self-pip-%s", var.projectPrefix, random_id.buildSuffix.hex)
#   location            = azurerm_resource_group.main.location
#   sku                 = "Standard"
#   resource_group_name = azurerm_resource_group.main.name
#   allocation_method   = "Static"
#   tags = {
#     owner = var.resourceOwner
#   }
# }

# resource "azurerm_public_ip" "vm02selfpip" {
#   name                = format("%s-vm02-self-pip-%s", var.projectPrefix, random_id.buildSuffix.hex)
#   location            = azurerm_resource_group.main.location
#   sku                 = "Standard"
#   resource_group_name = azurerm_resource_group.main.name
#   allocation_method   = "Static"
#   tags = {
#     owner = var.resourceOwner
#   }
# }

# # Create Public IPs - VIP
# resource "azurerm_public_ip" "pubvippip" {
#   name                = format("%s-pubvip-pip-%s", var.projectPrefix, random_id.buildSuffix.hex)
#   location            = azurerm_resource_group.main.location
#   sku                 = "Standard"
#   resource_group_name = azurerm_resource_group.main.name
#   allocation_method   = "Static"
#   tags = {
#     owner = var.resourceOwner
#   }
# }

############################ Network Interfaces ############################
# # Create NIC for Management
# resource "azurerm_network_interface" "vm01-mgmt-nic" {
#   name                = format("%s-vm01-mgmt-%s", var.projectPrefix, random_id.buildSuffix.hex)
#   location            = azurerm_resource_group.main.location
#   resource_group_name = azurerm_resource_group.main.name

#   ip_configuration {
#     name                          = "primary"
#     subnet_id                     = data.azurerm_subnet.mgmt.id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.vm01mgmtpip.id
#   }

#   tags = {
#     owner = var.resourceOwner
#   }
# }

# resource "azurerm_network_interface" "vm02-mgmt-nic" {
#   name                = format("%s-vm02-mgmt-%s", var.projectPrefix, random_id.buildSuffix.hex)
#   location            = azurerm_resource_group.main.location
#   resource_group_name = azurerm_resource_group.main.name

#   ip_configuration {
#     name                          = "primary"
#     subnet_id                     = data.azurerm_subnet.mgmt.id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.vm02mgmtpip.id
#   }

#   tags = {
#     owner = var.resourceOwner
#   }
# }

# # Create NIC for External
# resource "azurerm_network_interface" "vm01-ext-nic" {
#   name                 = format("%s-vm01-ext-%s", var.projectPrefix, random_id.buildSuffix.hex)
#   location             = azurerm_resource_group.main.location
#   resource_group_name  = azurerm_resource_group.main.name
#   enable_ip_forwarding = true

#   ip_configuration {
#     name                          = "primary"
#     subnet_id                     = data.azurerm_subnet.external.id
#     private_ip_address_allocation = "Dynamic"
#     primary                       = true
#     public_ip_address_id          = azurerm_public_ip.vm01selfpip.id
#   }
#   ip_configuration {
#     name                          = "secondary"
#     subnet_id                     = data.azurerm_subnet.external.id
#     private_ip_address_allocation = "Dynamic"
#     public_ip_address_id          = azurerm_public_ip.pubvippip.id
#   }

#   tags = {
#     owner                     = var.resourceOwner
#     f5_cloud_failover_label   = format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)
#     f5_cloud_failover_nic_map = "external"
#   }
# }

# resource "azurerm_network_interface" "vm02-ext-nic" {
#   name                 = format("%s-vm02-ext-%s", var.projectPrefix, random_id.buildSuffix.hex)
#   location             = azurerm_resource_group.main.location
#   resource_group_name  = azurerm_resource_group.main.name
#   enable_ip_forwarding = true

#   ip_configuration {
#     name                          = "primary"
#     subnet_id                     = data.azurerm_subnet.external.id
#     private_ip_address_allocation = "Dynamic"
#     primary                       = true
#     public_ip_address_id          = azurerm_public_ip.vm02selfpip.id
#   }

#   tags = {
#     owner                     = var.resourceOwner
#     f5_cloud_failover_label   = format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)
#     f5_cloud_failover_nic_map = "external"
#   }
# }

# # Create NIC for Internal
# resource "azurerm_network_interface" "vm01-int-nic" {
#   name                 = format("%s-vm01-int-%s", var.projectPrefix, random_id.buildSuffix.hex)
#   location             = azurerm_resource_group.main.location
#   resource_group_name  = azurerm_resource_group.main.name
#   enable_ip_forwarding = true

#   ip_configuration {
#     name                          = "primary"
#     subnet_id                     = data.azurerm_subnet.internal.id
#     private_ip_address_allocation = "Dynamic"
#     primary                       = true
#   }

#   tags = {
#     owner                     = var.resourceOwner
#     f5_cloud_failover_label   = format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)
#     f5_cloud_failover_nic_map = "internal"
#   }
# }

# resource "azurerm_network_interface" "vm02-int-nic" {
#   name                 = format("%s-vm02-int-%s", var.projectPrefix, random_id.buildSuffix.hex)
#   location             = azurerm_resource_group.main.location
#   resource_group_name  = azurerm_resource_group.main.name
#   enable_ip_forwarding = true

#   ip_configuration {
#     name                          = "primary"
#     subnet_id                     = data.azurerm_subnet.internal.id
#     private_ip_address_allocation = "Dynamic"
#     primary                       = true
#   }

#   tags = {
#     owner                     = var.resourceOwner
#     f5_cloud_failover_label   = format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)
#     f5_cloud_failover_nic_map = "internal"
#   }
# }

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
    CFE_URL                    = var.CFE_URL
    FAST_URL                   = var.FAST_URL
    DO_VER                     = split("/", var.DO_URL)[7]
    AS3_VER                    = split("/", var.AS3_URL)[7]
    TS_VER                     = split("/", var.TS_URL)[7]
    CFE_VER                    = split("/", var.CFE_URL)[7]
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
    # cluster info
    host1                   = module.bigip.private_addresses["mgmt_private"]["private_ip"][0]
    host2                   = module.bigip2.private_addresses["mgmt_private"]["private_ip"][0]
    remote_selfip_ext       = module.bigip2.private_addresses["public_private"]["private_ip"][0]
    vip_az1                 = local.vm01_vip_ips.app1.ip
    vip_az2                 = local.vm02_vip_ips.app1.ip
    f5_cloud_failover_label = format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)
    cfe_managed_route       = var.cfe_managed_route
  })
  f5_onboard2 = templatefile("${path.module}/f5_onboard.tmpl", {
    regKey                     = var.license2
    f5_username                = var.f5_username
    f5_password                = var.f5_password
    az_keyvault_authentication = var.az_keyvault_authentication
    vault_url                  = var.az_keyvault_authentication ? var.keyvault_url : ""
    ssh_keypair                = file(var.ssh_key)
    INIT_URL                   = var.INIT_URL
    DO_URL                     = var.DO_URL
    AS3_URL                    = var.AS3_URL
    TS_URL                     = var.TS_URL
    CFE_URL                    = var.CFE_URL
    FAST_URL                   = var.FAST_URL
    DO_VER                     = split("/", var.DO_URL)[7]
    AS3_VER                    = split("/", var.AS3_URL)[7]
    TS_VER                     = split("/", var.TS_URL)[7]
    CFE_VER                    = split("/", var.CFE_URL)[7]
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
    # cluster info
    host1                   = module.bigip.private_addresses["mgmt_private"]["private_ip"][0]
    host2                   = module.bigip2.private_addresses["mgmt_private"]["private_ip"][0]
    remote_selfip_ext       = module.bigip2.private_addresses["public_private"]["private_ip"][0]
    vip_az1                 = local.vm01_vip_ips.app1.ip
    vip_az2                 = local.vm02_vip_ips.app1.ip
    f5_cloud_failover_label = format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)
    cfe_managed_route       = var.cfe_managed_route
  })
}

############################ Compute ############################

# Create F5 BIG-IP VMs
module "bigip" {
  source                     = "github.com/F5Networks/terraform-azure-bigip-module"
  prefix                     = var.projectPrefix
  resource_group_name        = azurerm_resource_group.main.name
  f5_instance_type           = var.instance_type
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

module "bigip2" {
  source                     = "github.com/F5Networks/terraform-azure-bigip-module"
  prefix                     = var.projectPrefix
  resource_group_name        = azurerm_resource_group.main.name
  f5_instance_type           = var.instance_type
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
  #az_user_identity           = var.user_identity
}


# # Create F5 BIG-IP VMs
# resource "azurerm_linux_virtual_machine" "f5vm01" {
#   name                  = format("%s-f5vm01-%s", var.projectPrefix, random_id.buildSuffix.hex)
#   location              = azurerm_resource_group.main.location
#   resource_group_name   = azurerm_resource_group.main.name
#   zone                  = 1
#   network_interface_ids = [azurerm_network_interface.vm01-mgmt-nic.id, azurerm_network_interface.vm01-ext-nic.id, azurerm_network_interface.vm01-int-nic.id]
#   size                  = var.instance_type
#   admin_username        = var.f5_username
#   custom_data           = base64encode(local.f5_onboard1)

#   admin_ssh_key {
#     username   = var.f5_username
#     public_key = var.ssh_key
#   }

#   os_disk {
#     name                 = format("%s-vm01-osdisk-%s", var.projectPrefix, random_id.buildSuffix.hex)
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "f5-networks"
#     offer     = var.product
#     sku       = var.image_name
#     version   = var.bigip_version
#   }

#   plan {
#     name      = var.image_name
#     publisher = "f5-networks"
#     product   = var.product
#   }

#   identity {
#     type = "SystemAssigned"
#   }

#   tags = {
#     owner = var.resourceOwner
#   }
# }

# resource "azurerm_linux_virtual_machine" "f5vm02" {
#   name                  = format("%s-f5vm02-%s", var.projectPrefix, random_id.buildSuffix.hex)
#   location              = azurerm_resource_group.main.location
#   resource_group_name   = azurerm_resource_group.main.name
#   zone                  = 2
#   network_interface_ids = [azurerm_network_interface.vm02-mgmt-nic.id, azurerm_network_interface.vm02-ext-nic.id, azurerm_network_interface.vm02-int-nic.id]
#   size                  = var.instance_type
#   admin_username        = var.f5_username
#   custom_data           = base64encode(local.f5_onboard2)

#   admin_ssh_key {
#     username   = var.f5_username
#     public_key = var.ssh_key
#   }

#   os_disk {
#     name                 = format("%s-vm02-osdisk-%s", var.projectPrefix, random_id.buildSuffix.hex)
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "f5-networks"
#     offer     = var.product
#     sku       = var.image_name
#     version   = var.bigip_version
#   }

#   plan {
#     name      = var.image_name
#     publisher = "f5-networks"
#     product   = var.product
#   }

#   identity {
#     type = "SystemAssigned"
#   }

#   tags = {
#     owner = var.resourceOwner
#   }
# }

############################ Assign Managed Identity to VMs ############################

# Retrieve VM info
data "azurerm_virtual_machine" "f5vm01" {
  name                = element(split("/", module.bigip.bigip_instance_ids), 8)
  resource_group_name = azurerm_resource_group.main.name
}
data "azurerm_virtual_machine" "f5vm02" {
  name                = element(split("/", module.bigip2.bigip_instance_ids), 8)
  resource_group_name = azurerm_resource_group.main.name
}

# Configure VMs to use a system-assigned managed identity
resource "azurerm_role_assignment" "f5vm01ra" {
  scope                = data.azurerm_subscription.main.id
  role_definition_name = "Contributor"
  principal_id         = lookup(data.azurerm_virtual_machine.f5vm01.identity[0], "principal_id")
}
resource "azurerm_role_assignment" "f5vm02ra" {
  scope                = data.azurerm_subscription.main.id
  role_definition_name = "Contributor"
  principal_id         = lookup(data.azurerm_virtual_machine.f5vm02.identity[0], "principal_id")
}

############################ Azure Extensions (onboarding) ############################

# # Run Startup Script
# resource "azurerm_virtual_machine_extension" "f5vm01-startup" {
#   name                 = format("%s-f5vm01-startup-%s", var.projectPrefix, random_id.buildSuffix.hex)
#   virtual_machine_id   = azurerm_linux_virtual_machine.f5vm01.id
#   publisher            = "Microsoft.Azure.Extensions"
#   type                 = "CustomScript"
#   type_handler_version = "2.0"

#   settings = <<SETTINGS
#     {
#         "commandToExecute": "bash /var/lib/waagent/CustomData; exit 0;"
#     }
#   SETTINGS

#   tags = {
#     owner = var.resourceOwner
#   }
# }

# resource "azurerm_virtual_machine_extension" "f5vm02-startup" {
#   name                 = format("%s-f5vm02-startup-%s", var.projectPrefix, random_id.buildSuffix.hex)
#   virtual_machine_id   = azurerm_linux_virtual_machine.f5vm02.id
#   publisher            = "Microsoft.Azure.Extensions"
#   type                 = "CustomScript"
#   type_handler_version = "2.0"

#   settings = <<SETTINGS
#     {
#         "commandToExecute": "bash /var/lib/waagent/CustomData; exit 0;"
#     }
#   SETTINGS

#   tags = {
#     owner = var.resourceOwner
#   }
# }

############################ Route Tables ############################

# # Create Route Table
# resource "azurerm_route_table" "udr" {
#   name                          = format("%s-udr-%s", var.projectPrefix, random_id.buildSuffix.hex)
#   location                      = azurerm_resource_group.main.location
#   resource_group_name           = azurerm_resource_group.main.name
#   disable_bgp_route_propagation = false

#   route {
#     name                   = "route1"
#     address_prefix         = var.cfe_managed_route
#     next_hop_type          = "VirtualAppliance"
#     next_hop_in_ip_address = azurerm_network_interface.vm02-ext-nic.private_ip_address
#   }

#   tags = {
#     owner                   = var.resourceOwner
#     f5_cloud_failover_label = format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)
#     f5_self_ips             = "${azurerm_network_interface.vm01-ext-nic.private_ip_address},${azurerm_network_interface.vm02-ext-nic.private_ip_address}"
#   }
# }

############################ Tagging ############################

# resource "null_resource" "cluster" {
#   # Changes to any instance of the cluster requires re-provisioning
#   triggers = {
#     bigip_instance_ids = join(",", aws_instance.cluster.*.id)
#   }

#   # Bootstrap script can run on any instance of the cluster
#   # So we just choose the first in this case
#   connection {
#     host = element(aws_instance.cluster.*.public_ip, 0)
#   }

#   provisioner "remote-exec" {
#     # Bootstrap script called with private_ip of each node in the clutser
#     inline = [
#       "bootstrap-cluster.sh ${join(" ", aws_instance.cluster.*.private_ip)}",
#     ]
#   }
# }
