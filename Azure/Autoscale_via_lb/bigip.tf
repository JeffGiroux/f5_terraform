# BIG-IP

# Create a Network Security Group and rules
resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "allow_SSH"
    description                = "Allow SSH access"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_HTTP"
    description                = "Allow HTTP access"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_HTTPS"
    description                = "Allow HTTPS access"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_APP_HTTPS"
    description                = "Allow HTTPS access"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Name        = "${var.environment}-bigip-sg"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = var.application
  }
}

# Setup Onboarding scripts
data "template_file" "vm_onboard" {
  template = file("${path.module}/onboard.tpl")

  vars = {
    admin_user     = var.uname
    admin_password = var.upassword
    DO_URL         = var.DO_URL
    AS3_URL        = var.AS3_URL
    TS_URL         = var.TS_URL
    libs_dir       = var.libs_dir
    onboard_log    = var.onboard_log
    DO_Document    = data.template_file.vm01_do_json.rendered
    AS3_Document   = data.template_file.as3_json.rendered
    TS_Document    = data.template_file.ts_json.rendered
  }
}

data "template_file" "vm01_do_json" {
  template = file("${path.module}/do.json")

  vars = {
    local_host         = "-device-hostname-"
    local_selfip       = "-external-self-address-"
    gateway            = var.ext_gw
    dns_server         = var.dns_server
    ntp_server         = var.ntp_server
    timezone           = var.timezone
    bigIqLicenseType   = var.bigIqLicenseType
    bigIqHost          = var.bigIqHost
    bigIqUsername      = var.bigIqUsername
    bigIqPassword      = var.bigIqPassword
    bigIqLicensePool   = var.bigIqLicensePool
    bigIqSkuKeyword1   = var.bigIqSkuKeyword1
    bigIqSkuKeyword2   = var.bigIqSkuKeyword2
    bigIqUnitOfMeasure = var.bigIqUnitOfMeasure
    bigIqHypervisor    = var.bigIqHypervisor
  }
}

data "template_file" "as3_json" {
  template = file("${path.module}/as3.json")

  vars = {
    rg_name         = azurerm_resource_group.main.name
    subscription_id = var.sp_subscription_id
    tenant_id       = var.sp_tenant_id
    client_id       = var.sp_client_id
    client_secret   = var.sp_client_secret
    backendvm_ip    = var.backend01ext
  }
}

data "template_file" "ts_json" {
  template   = file("${path.module}/ts.json")

  vars = {
    region      = var.location
    law_id      = azurerm_log_analytics_workspace.law.workspace_id
    law_primkey = azurerm_log_analytics_workspace.law.primary_shared_key
  }
}

# Create F5 BIG-IP VMs
resource "azurerm_linux_virtual_machine_scale_set" "f5vmss" {
  name                            = "${var.prefix}-f5vmss"
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  sku                             = var.instance_type
  instances                       = 2
  admin_username                  = var.uname
  admin_password                  = var.upassword
  disable_password_authentication = false
  computer_name_prefix            = "${var.prefix}f5vm"
  custom_data                     = base64encode(data.template_file.vm_onboard.rendered)

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
    name                      = "mgmt"
    primary                   = true
    network_security_group_id = azurerm_network_security_group.main.id

    ip_configuration {
      name      = "mgmt"
      primary   = true
      subnet_id = azurerm_subnet.Mgmt.id

      public_ip_address {
        name = "mgmt-pip"
      }
    }
  }

  network_interface {
    name                      = "external"
    primary                   = false
    network_security_group_id = azurerm_network_security_group.main.id

    ip_configuration {
      name      = "primary"
      primary   = true
      subnet_id = azurerm_subnet.External.id

      public_ip_address {
        name = "selfip-pip"
      }
    }

    ip_configuration {
      name                                   = "secondary"
      primary                                = false
      subnet_id                              = azurerm_subnet.External.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.backend_pool.id]
    }
  }

  tags = {
    Name        = "${var.environment}-f5vmss"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = var.application
  }
}

## Troubleshooting - create local output files
# resource "local_file" "onboard_file" {
#   content  = data.template_file.vm_onboard.rendered
#   filename = "${path.module}/vm_onboard.tpl_data.json"
# }

# resource "local_file" "do_file" {
#   content  = data.template_file.vm01_do_json.rendered
#   filename = "${path.module}/vm01_do_data.json"
# }

# resource "local_file" "as3_file" {
#   content  = data.template_file.as3_json.rendered
#   filename = "${path.module}/vm_as3_data.json"
# }

# resource "local_file" "ts_file" {
#   content  = data.template_file.ts_json.rendered
#   filename = "${path.module}/vm_ts_data.json"
# }
