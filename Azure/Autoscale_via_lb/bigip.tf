# BIG-IP Cluster


# Setup Onboarding scripts
locals {
  f5_onboard1 = templatefile("${path.module}/f5_onboard.tmpl", {
    f5_username        = var.uname
    f5_password        = var.upassword
    ssh_keypair        = var.ssh_key
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
    law_id             = azurerm_log_analytics_workspace.law.workspace_id
    law_primkey        = azurerm_log_analytics_workspace.law.primary_shared_key
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
resource "azurerm_linux_virtual_machine_scale_set" "f5vmss" {
  name                            = format("%s-f5vmss-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  sku                             = var.instance_type
  instances                       = 2
  admin_username                  = var.uname
  admin_password                  = var.upassword
  disable_password_authentication = false
  computer_name_prefix            = "${var.projectPrefix}f5vm"
  custom_data                     = base64encode(local.f5_onboard1)

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "f5-networks"
    offer     = var.product
    sku       = var.image_name
    version   = var.bigip_version
  }

  plan {
    name      = var.image_name
    publisher = "f5-networks"
    product   = var.product
  }

  network_interface {
    name    = "mgmt"
    primary = true
    ip_configuration {
      name      = "mgmt"
      primary   = true
      subnet_id = data.azurerm_subnet.mgmt.id
      public_ip_address {
        name = "mgmt-pip"
      }
    }
  }

  network_interface {
    name    = "external"
    primary = false
    ip_configuration {
      name      = "primary"
      primary   = true
      subnet_id = data.azurerm_subnet.external.id

      public_ip_address {
        name = "selfip-pip"
      }
    }
    ip_configuration {
      name                                   = "secondary"
      primary                                = false
      subnet_id                              = data.azurerm_subnet.external.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.backend_pool.id]
    }
  }

  network_interface {
    name    = "internal"
    primary = false
    ip_configuration {
      name      = "primary"
      primary   = true
      subnet_id = data.azurerm_subnet.internal.id
    }
    ip_configuration {
      name      = "secondary"
      primary   = false
      subnet_id = data.azurerm_subnet.internal.id
    }
  }

  tags = {
    owner = var.owner
  }
}
