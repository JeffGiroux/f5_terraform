############################ Public IP ############################

# Create Public IP - mgmt
resource "azurerm_public_ip" "bigipMgmtPip" {
  name                = format("%s-bigip-mgmt-pip-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  availability_zone   = 1
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  tags = {
    owner = var.owner
  }
}

# Create Public IPv4 - external BIG-IP self IP
resource "azurerm_public_ip" "bigipSelfPip" {
  name                = format("%s-bigip-self-pip-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  availability_zone   = 1
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  ip_version          = "IPv4"
  tags = {
    owner = var.owner
  }
}

# Create Public IPv6 - external BIG-IP self IP
resource "azurerm_public_ip" "bigipSelfPipV6" {
  name                = format("%s-bigip-self-pipv6-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  availability_zone   = 1
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  ip_version          = "IPv6"
  tags = {
    owner = var.owner
  }
}

# Create Public IPv4 - VIP
resource "azurerm_public_ip" "bigipVipPip" {
  name                = format("%s-bigip-vip-pip-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  availability_zone   = 1
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  tags = {
    owner = var.owner
  }
}

############################ NIC ############################

# Create NIC for Management
resource "azurerm_network_interface" "bigipMgmtNic" {
  name                = format("%s-bigip-mgmt-nic-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.mgmt.id
    private_ip_address_version    = "IPv4"
    private_ip_address_allocation = "Static"
    private_ip_address            = var.bigipMgmtPrivateIp4
    public_ip_address_id          = azurerm_public_ip.bigipMgmtPip.id
  }
  tags = {
    owner = var.owner
  }
}

# Create NIC for External
resource "azurerm_network_interface" "bigipExtNic" {
  name                 = format("%s-bigip-ext-nic-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  enable_ip_forwarding = true
  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.external.id
    private_ip_address_version    = "IPv4"
    private_ip_address_allocation = "Static"
    private_ip_address            = var.bigipExtPrivateIp4
    public_ip_address_id          = azurerm_public_ip.bigipSelfPip.id
    primary                       = true
  }
  ip_configuration {
    name                          = "secondary"
    subnet_id                     = azurerm_subnet.external.id
    private_ip_address_version    = "IPv4"
    private_ip_address_allocation = "Static"
    private_ip_address            = var.bigipExtSecondaryIp4
    public_ip_address_id          = azurerm_public_ip.bigipVipPip.id
  }
  ip_configuration {
    name                          = "secondary-ipv6"
    subnet_id                     = azurerm_subnet.external.id
    private_ip_address_version    = "IPv6"
    private_ip_address_allocation = "Static"
    private_ip_address            = var.bigipExtPrivateIp6
    public_ip_address_id          = azurerm_public_ip.bigipSelfPipV6.id
  }
  tags = {
    owner = var.owner
  }
}

# Create NIC for Internal
resource "azurerm_network_interface" "bigipIntNic" {
  name                 = format("%s-bigip-int-nic-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  enable_ip_forwarding = true
  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_version    = "IPv4"
    private_ip_address_allocation = "Static"
    private_ip_address            = var.bigipIntPrivateIp4
    primary                       = true
  }
  ip_configuration {
    name                          = "secondary"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_version    = "IPv4"
    private_ip_address_allocation = "Static"
    private_ip_address            = var.bigipIntSecondaryIp4
  }
  ip_configuration {
    name                          = "secondary-ipv6"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_version    = "IPv6"
    private_ip_address_allocation = "Static"
    private_ip_address            = var.bigipIntPrivateIp6
  }
  tags = {
    owner = var.owner
  }
}

############################ Scripts ############################

# Setup Onboarding scripts
locals {
  f5_onboard = templatefile("${path.module}/f5_onboard.tmpl", {
    regKey              = var.license1
    f5_username         = var.uname
    f5_password         = var.upassword
    ssh_keypair         = var.ssh_key
    INIT_URL            = var.INIT_URL
    DO_URL              = var.DO_URL
    AS3_URL             = var.AS3_URL
    TS_URL              = var.TS_URL
    FAST_URL            = var.FAST_URL
    DO_VER              = split("/", var.DO_URL)[7]
    AS3_VER             = split("/", var.AS3_URL)[7]
    TS_VER              = split("/", var.TS_URL)[7]
    FAST_VER            = split("/", var.FAST_URL)[7]
    self_ip_external    = var.bigipExtPrivateIp4
    self_ip_external_v6 = var.bigipExtPrivateIp6
    external_vip_ip     = var.bigipExtSecondaryIp4
    self_ip_internal    = var.bigipIntPrivateIp4
    self_ip_internal_v6 = var.bigipIntPrivateIp6
    internal_vip_ip     = var.bigipIntSecondaryIp4
    link_local_address  = var.linkLocalAddress
    dns_server          = var.dns_server
    ntp_server          = var.ntp_server
    timezone            = var.timezone
    bigIqLicenseType    = var.bigIqLicenseType
    bigIqHost           = var.bigIqHost
    bigIqPassword       = var.bigIqPassword
    bigIqUsername       = var.bigIqUsername
    bigIqLicensePool    = var.bigIqLicensePool
    bigIqSkuKeyword1    = var.bigIqSkuKeyword1
    bigIqSkuKeyword2    = var.bigIqSkuKeyword2
    bigIqUnitOfMeasure  = var.bigIqUnitOfMeasure
    bigIqHypervisor     = var.bigIqHypervisor
  })
}

############################ Compute ############################

# Create F5 BIG-IP VM
resource "azurerm_linux_virtual_machine" "bigip" {
  name                            = format("%s-bigip-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  network_interface_ids           = [azurerm_network_interface.bigipMgmtNic.id, azurerm_network_interface.bigipExtNic.id, azurerm_network_interface.bigipIntNic.id]
  size                            = var.instance_type
  admin_username                  = var.uname
  admin_password                  = var.upassword
  disable_password_authentication = false
  custom_data                     = base64encode(local.f5_onboard)
  admin_ssh_key {
    username   = var.uname
    public_key = var.ssh_key
  }
  os_disk {
    name                 = format("%s-bigip-disk-%s", var.projectPrefix, random_id.buildSuffix.hex)
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
  tags = {
    owner = var.owner
  }
}

# Run Startup Script
resource "azurerm_virtual_machine_extension" "bigip-startup" {
  name                 = format("%s-bigip-startup-%s", var.projectPrefix, random_id.buildSuffix.hex)
  virtual_machine_id   = azurerm_linux_virtual_machine.bigip.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"
  settings             = <<SETTINGS
    {
        "commandToExecute": "bash /var/lib/waagent/CustomData; exit 0;"
    }
  SETTINGS
  tags = {
    owner = var.owner
  }
}
