# BIG-IP Cluster

# Create Public IPs - mgmt
resource "azurerm_public_ip" "vm01mgmtpip" {
  name                = format("%s-vm01-mgmt-pip-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  tags = {
    owner = var.owner
  }
}

resource "azurerm_public_ip" "vm02mgmtpip" {
  name                = format("%s-vm02-mgmt-pip-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  tags = {
    owner = var.owner
  }
}

# Create Public IPs - external
resource "azurerm_public_ip" "vm01selfpip" {
  name                = format("%s-vm01-self-pip-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  tags = {
    owner = var.owner
  }
}

resource "azurerm_public_ip" "vm02selfpip" {
  name                = format("%s-vm02-self-pip-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  tags = {
    owner = var.owner
  }
}

# Create Public IPs - VIP
resource "azurerm_public_ip" "pubvippip" {
  name                = format("%s-pubvip-pip-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  tags = {
    owner = var.owner
  }
}

# Create NIC for Management
resource "azurerm_network_interface" "vm01-mgmt-nic" {
  name                = format("%s-vm01-mgmt-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = data.azurerm_subnet.mgmt.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm01mgmtpip.id
  }

  tags = {
    owner = var.owner
  }
}

resource "azurerm_network_interface" "vm02-mgmt-nic" {
  name                = format("%s-vm02-mgmt-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = data.azurerm_subnet.mgmt.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm02mgmtpip.id
  }

  tags = {
    owner = var.owner
  }
}

# Create NIC for External
resource "azurerm_network_interface" "vm01-ext-nic" {
  name                 = format("%s-vm01-ext-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "primary"
    subnet_id                     = data.azurerm_subnet.external.id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.vm01selfpip.id
  }
  ip_configuration {
    name                          = "secondary"
    subnet_id                     = data.azurerm_subnet.external.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pubvippip.id
  }

  tags = {
    owner                     = var.owner
    f5_cloud_failover_label   = format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)
    f5_cloud_failover_nic_map = var.f5_cloud_failover_nic_map
  }
}

resource "azurerm_network_interface" "vm02-ext-nic" {
  name                 = format("%s-vm02-ext-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "primary"
    subnet_id                     = data.azurerm_subnet.external.id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.vm02selfpip.id
  }

  tags = {
    owner                     = var.owner
    f5_cloud_failover_label   = format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)
    f5_cloud_failover_nic_map = var.f5_cloud_failover_nic_map
  }
}

# Create NIC for Internal
resource "azurerm_network_interface" "vm01-int-nic" {
  name                 = format("%s-vm01-int-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "primary"
    subnet_id                     = data.azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
  }

  tags = {
    owner = var.owner
  }
}

resource "azurerm_network_interface" "vm02-int-nic" {
  name                 = format("%s-vm02-int-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "primary"
    subnet_id                     = data.azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    primary                       = true
  }

  tags = {
    owner = var.owner
  }
}

# Setup Onboarding scripts
locals {
  f5_onboard1 = templatefile("${path.module}/f5_onboard.tmpl", {
    regKey                  = var.license1
    f5_username             = var.uname
    f5_password             = var.upassword
    ssh_keypair             = var.ssh_key
    INIT_URL                = var.INIT_URL
    DO_URL                  = var.DO_URL
    AS3_URL                 = var.AS3_URL
    TS_URL                  = var.TS_URL
    CFE_URL                 = var.CFE_URL
    FAST_URL                = var.FAST_URL
    DO_VER                  = split("/", var.DO_URL)[7]
    AS3_VER                 = split("/", var.AS3_URL)[7]
    TS_VER                  = split("/", var.TS_URL)[7]
    CFE_VER                 = split("/", var.CFE_URL)[7]
    FAST_VER                = split("/", var.FAST_URL)[7]
    self_ip_external        = azurerm_network_interface.vm01-ext-nic.private_ip_address
    self_ip_internal        = azurerm_network_interface.vm01-int-nic.private_ip_address
    remote_selfip_ext       = ""
    dns_server              = var.dns_server
    ntp_server              = var.ntp_server
    timezone                = var.timezone
    host1                   = format("%s-f5vm01-%s", var.projectPrefix, random_id.buildSuffix.hex)
    host2                   = format("%s-f5vm02-%s", var.projectPrefix, random_id.buildSuffix.hex)
    remote_host             = format("%s-f5vm02-%s", var.projectPrefix, random_id.buildSuffix.hex)
    f5_cloud_failover_label = format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)
    cfe_managed_route       = var.cfe_managed_route
    law_id                  = azurerm_log_analytics_workspace.law.workspace_id
    law_primkey             = azurerm_log_analytics_workspace.law.primary_shared_key
    bigIqLicenseType        = var.bigIqLicenseType
    bigIqHost               = var.bigIqHost
    bigIqPassword           = var.bigIqPassword
    bigIqUsername           = var.bigIqUsername
    bigIqLicensePool        = var.bigIqLicensePool
    bigIqSkuKeyword1        = var.bigIqSkuKeyword1
    bigIqSkuKeyword2        = var.bigIqSkuKeyword2
    bigIqUnitOfMeasure      = var.bigIqUnitOfMeasure
    bigIqHypervisor         = var.bigIqHypervisor
  })
  f5_onboard2 = templatefile("${path.module}/f5_onboard.tmpl", {
    regKey                  = var.license2
    f5_username             = var.uname
    f5_password             = var.upassword
    ssh_keypair             = var.ssh_key
    INIT_URL                = var.INIT_URL
    DO_URL                  = var.DO_URL
    AS3_URL                 = var.AS3_URL
    TS_URL                  = var.TS_URL
    CFE_URL                 = var.CFE_URL
    FAST_URL                = var.FAST_URL
    DO_VER                  = split("/", var.DO_URL)[7]
    AS3_VER                 = split("/", var.AS3_URL)[7]
    TS_VER                  = split("/", var.TS_URL)[7]
    CFE_VER                 = split("/", var.CFE_URL)[7]
    FAST_VER                = split("/", var.FAST_URL)[7]
    self_ip_external        = azurerm_network_interface.vm02-ext-nic.private_ip_address
    self_ip_internal        = azurerm_network_interface.vm02-int-nic.private_ip_address
    remote_selfip_ext       = azurerm_network_interface.vm01-ext-nic.private_ip_address
    dns_server              = var.dns_server
    ntp_server              = var.ntp_server
    timezone                = var.timezone
    host1                   = format("%s-f5vm01-%s", var.projectPrefix, random_id.buildSuffix.hex)
    host2                   = format("%s-f5vm02-%s", var.projectPrefix, random_id.buildSuffix.hex)
    remote_host             = azurerm_network_interface.vm01-int-nic.private_ip_address
    f5_cloud_failover_label = format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)
    cfe_managed_route       = var.cfe_managed_route
    law_id                  = azurerm_log_analytics_workspace.law.workspace_id
    law_primkey             = azurerm_log_analytics_workspace.law.primary_shared_key
    bigIqLicenseType        = var.bigIqLicenseType
    bigIqHost               = var.bigIqHost
    bigIqPassword           = var.bigIqPassword
    bigIqUsername           = var.bigIqUsername
    bigIqLicensePool        = var.bigIqLicensePool
    bigIqSkuKeyword1        = var.bigIqSkuKeyword1
    bigIqSkuKeyword2        = var.bigIqSkuKeyword2
    bigIqUnitOfMeasure      = var.bigIqUnitOfMeasure
    bigIqHypervisor         = var.bigIqHypervisor
  })
}

# Create F5 BIG-IP VMs
resource "azurerm_linux_virtual_machine" "f5vm01" {
  name                            = format("%s-f5vm01-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  zone                            = 1
  network_interface_ids           = [azurerm_network_interface.vm01-mgmt-nic.id, azurerm_network_interface.vm01-ext-nic.id, azurerm_network_interface.vm01-int-nic.id]
  size                            = var.instance_type
  admin_username                  = var.uname
  admin_password                  = var.upassword
  disable_password_authentication = false
  custom_data                     = base64encode(local.f5_onboard1)

  admin_ssh_key {
    username   = var.uname
    public_key = var.ssh_key
  }

  os_disk {
    name                 = format("%s-vm01-osdisk-%s", var.projectPrefix, random_id.buildSuffix.hex)
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

  identity {
    type = "SystemAssigned"
  }

  tags = {
    owner = var.owner
  }
}

resource "azurerm_linux_virtual_machine" "f5vm02" {
  name                            = format("%s-f5vm02-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  zone                            = 2
  network_interface_ids           = [azurerm_network_interface.vm02-mgmt-nic.id, azurerm_network_interface.vm02-ext-nic.id, azurerm_network_interface.vm02-int-nic.id]
  size                            = var.instance_type
  admin_username                  = var.uname
  admin_password                  = var.upassword
  disable_password_authentication = false
  custom_data                     = base64encode(local.f5_onboard2)

  admin_ssh_key {
    username   = var.uname
    public_key = var.ssh_key
  }

  os_disk {
    name                 = format("%s-vm02-osdisk-%s", var.projectPrefix, random_id.buildSuffix.hex)
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

  identity {
    type = "SystemAssigned"
  }

  tags = {
    owner = var.owner
  }
}

# Configure VMs to use a system-assigned managed identity
resource "azurerm_role_assignment" "f5vm01ra" {
  scope                = data.azurerm_subscription.main.id
  role_definition_name = "Contributor"
  principal_id         = lookup(azurerm_linux_virtual_machine.f5vm01.identity[0], "principal_id")
}

resource "azurerm_role_assignment" "f5vm02ra" {
  scope                = data.azurerm_subscription.main.id
  role_definition_name = "Contributor"
  principal_id         = lookup(azurerm_linux_virtual_machine.f5vm02.identity[0], "principal_id")
}

# Run Startup Script
resource "azurerm_virtual_machine_extension" "f5vm01-startup" {
  name                 = format("%s-f5vm01-startup-%s", var.projectPrefix, random_id.buildSuffix.hex)
  virtual_machine_id   = azurerm_linux_virtual_machine.f5vm01.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "bash /var/lib/waagent/CustomData; exit 0;"
    }
  SETTINGS

  tags = {
    owner = var.owner
  }
}

resource "azurerm_virtual_machine_extension" "f5vm02-startup" {
  name                 = format("%s-f5vm02-startup-%s", var.projectPrefix, random_id.buildSuffix.hex)
  virtual_machine_id   = azurerm_linux_virtual_machine.f5vm02.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "bash /var/lib/waagent/CustomData; exit 0;"
    }
  SETTINGS

  tags = {
    owner = var.owner
  }
}

# Create Route Table
resource "azurerm_route_table" "udr" {
  name                          = format("%s-udr-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  disable_bgp_route_propagation = false

  route {
    name                   = "route1"
    address_prefix         = var.cfe_managed_route
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_network_interface.vm02-ext-nic.private_ip_address
  }

  tags = {
    owner                   = var.owner
    f5_cloud_failover_label = format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)
    f5_self_ips             = "${azurerm_network_interface.vm01-ext-nic.private_ip_address},${azurerm_network_interface.vm02-ext-nic.private_ip_address}"
  }
}
