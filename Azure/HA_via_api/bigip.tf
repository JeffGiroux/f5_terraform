# BIG-IP Cluster

# Create Route Table
resource "azurerm_route_table" "udr" {
  name                          = "udr"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  disable_bgp_route_propagation = false

  route {
    name                   = "route1"
    address_prefix         = var.managed_route1
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_network_interface.vm02-ext-nic.private_ip_address
  }

  tags = {
    f5_cloud_failover_label = var.f5_cloud_failover_label
    f5_self_ips             = "${azurerm_network_interface.vm01-ext-nic.private_ip_address},${azurerm_network_interface.vm02-ext-nic.private_ip_address}"
  }
}

# Create Public IPs
resource "azurerm_public_ip" "vm01mgmtpip" {
  name                = "${var.prefix}-vm01-mgmt-pip"
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  zones               = [1]
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"

  tags = {
    Name        = "${var.environment}-vm01-mgmt-public-ip"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = var.application
  }
}

resource "azurerm_public_ip" "vm01selfpip" {
  name                = "${var.prefix}-vm01-self-pip"
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  zones               = [1]
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"

  tags = {
    Name        = "${var.environment}-vm01-self-public-ip"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = var.application
  }
}

resource "azurerm_public_ip" "vm02mgmtpip" {
  name                = "${var.prefix}-vm02-mgmt-pip"
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  zones               = [2]
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"

  tags = {
    Name        = "${var.environment}-vm02-mgmt-public-ip"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = var.application
  }
}

resource "azurerm_public_ip" "vm02selfpip" {
  name                = "${var.prefix}-vm02-self-pip"
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  zones               = [2]
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"

  tags = {
    Name        = "${var.environment}-vm02-self-public-ip"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = var.application
  }
}

resource "azurerm_public_ip" "pubvippip" {
  name                = "${var.prefix}-pubvip-pip"
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  zones               = [1]
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"

  tags = {
    Name        = "${var.environment}-pubvip-public-ip"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = var.application
  }
}

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

# Create NIC for Management 
resource "azurerm_network_interface" "vm01-mgmt-nic" {
  name                = "${var.prefix}-mgmt0"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.Mgmt.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.f5vm01mgmt
    public_ip_address_id          = azurerm_public_ip.vm01mgmtpip.id
  }

  tags = {
    Name        = "${var.environment}-vm01-mgmt-int"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = var.application
  }
}

resource "azurerm_network_interface" "vm02-mgmt-nic" {
  name                = "${var.prefix}-mgmt1"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.Mgmt.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.f5vm02mgmt
    public_ip_address_id          = azurerm_public_ip.vm02mgmtpip.id
  }

  tags = {
    Name        = "${var.environment}-vm02-mgmt-int"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = var.application
  }
}

# Create NIC for External
resource "azurerm_network_interface" "vm01-ext-nic" {
  name                 = "${var.prefix}-ext0"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.External.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.f5vm01ext
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.vm01selfpip.id
  }

  tags = {
    Name                      = "${var.environment}-vm01-ext-int"
    environment               = var.environment
    owner                     = var.owner
    group                     = var.group
    costcenter                = var.costcenter
    application               = var.application
    f5_cloud_failover_label   = var.f5_cloud_failover_label
    f5_cloud_failover_nic_map = var.f5_cloud_failover_nic_map
  }
}

resource "azurerm_network_interface" "vm02-ext-nic" {
  name                 = "${var.prefix}-ext1"
  location             = azurerm_resource_group.main.location
  resource_group_name  = azurerm_resource_group.main.name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.External.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.f5vm02ext
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.vm02selfpip.id
  }

  ip_configuration {
    name                          = "secondary1"
    subnet_id                     = azurerm_subnet.External.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.f5privatevip
  }

  ip_configuration {
    name                          = "secondary2"
    subnet_id                     = azurerm_subnet.External.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.f5publicvip
    public_ip_address_id          = azurerm_public_ip.pubvippip.id
  }

  tags = {
    Name                      = "${var.environment}-vm02-ext-int"
    environment               = var.environment
    owner                     = var.owner
    group                     = var.group
    costcenter                = var.costcenter
    application               = var.application
    f5_cloud_failover_label   = var.f5_cloud_failover_label
    f5_cloud_failover_nic_map = var.f5_cloud_failover_nic_map
  }
}

# Associate network security groups with NICs
resource "azurerm_network_interface_security_group_association" "vm01-mgmt-nsg" {
  network_interface_id      = azurerm_network_interface.vm01-mgmt-nic.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_network_interface_security_group_association" "vm02-mgmt-nsg" {
  network_interface_id      = azurerm_network_interface.vm02-mgmt-nic.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_network_interface_security_group_association" "vm01-ext-nsg" {
  network_interface_id      = azurerm_network_interface.vm01-ext-nic.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_network_interface_security_group_association" "vm02-ext-nsg" {
  network_interface_id      = azurerm_network_interface.vm02-ext-nic.id
  network_security_group_id = azurerm_network_security_group.main.id
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
    CF_URL         = var.CF_URL
    libs_dir       = var.libs_dir
    onboard_log    = var.onboard_log
    mgmt_gw        = var.mgmt_gw
  }
}

data "template_file" "vm01_do_json" {
  template = file("${path.module}/do.json")

  vars = {
    regKey         = var.license1
    host1          = var.host1_name
    host2          = var.host2_name
    local_host     = var.host1_name
    local_selfip   = var.f5vm01ext
    remote_selfip  = var.f5vm02ext
    gateway        = var.ext_gw
    dns_server     = var.dns_server
    ntp_server     = var.ntp_server
    timezone       = var.timezone
    admin_user     = var.uname
    admin_password = var.upassword
  }
}

data "template_file" "vm02_do_json" {
  template = file("${path.module}/do.json")

  vars = {
    regKey         = var.license2
    host1          = var.host1_name
    host2          = var.host2_name
    local_host     = var.host2_name
    local_selfip   = var.f5vm02ext
    remote_selfip  = var.f5vm01ext
    gateway        = var.ext_gw
    dns_server     = var.dns_server
    ntp_server     = var.ntp_server
    timezone       = var.timezone
    admin_user     = var.uname
    admin_password = var.upassword
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
    publicvip       = var.f5publicvip
    privatevip      = var.f5privatevip
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

data "template_file" "failover_json" {
  template = file("${path.module}/failover.json")

  vars = {
    f5_cloud_failover_label = var.f5_cloud_failover_label
    managed_route1          = var.managed_route1
    local_selfip            = var.f5vm02ext
    remote_selfip           = var.f5vm01ext
  }
}

# Create F5 BIG-IP VMs
resource "azurerm_linux_virtual_machine" "f5vm01" {
  name                            = "${var.prefix}-f5vm01"
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  zone                            = 1
  network_interface_ids           = [azurerm_network_interface.vm01-mgmt-nic.id, azurerm_network_interface.vm01-ext-nic.id]
  size                            = var.instance_type
  admin_username                  = var.uname
  admin_password                  = var.upassword
  disable_password_authentication = false
  computer_name                   = "${var.prefix}vm01"
  custom_data                     = base64encode(data.template_file.vm_onboard.rendered)

  os_disk {
    name                 = "${var.prefix}vm01-osdisk"
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

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.mystorage.primary_blob_endpoint
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Name        = "${var.environment}-f5vm01"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = var.application
  }
}

resource "azurerm_linux_virtual_machine" "f5vm02" {
  name                            = "${var.prefix}-f5vm02"
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  zone                            = 2
  network_interface_ids           = [azurerm_network_interface.vm02-mgmt-nic.id, azurerm_network_interface.vm02-ext-nic.id]
  size                            = var.instance_type
  admin_username                  = var.uname
  admin_password                  = var.upassword
  disable_password_authentication = false
  computer_name                   = "${var.prefix}vm02"
  custom_data                     = base64encode(data.template_file.vm_onboard.rendered)

  os_disk {
    name                 = "${var.prefix}vm02-osdisk"
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

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.mystorage.primary_blob_endpoint
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Name        = "${var.environment}-f5vm02"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = var.application
  }
}

# Configure VMs to use a system-assigned managed identity
resource "azurerm_role_assignment" "f5vm01ra" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = lookup(azurerm_linux_virtual_machine.f5vm01.identity[0], "principal_id")
}

resource "azurerm_role_assignment" "f5vm02ra" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = lookup(azurerm_linux_virtual_machine.f5vm02.identity[0], "principal_id")
}

# Run Startup Script
resource "azurerm_virtual_machine_extension" "f5vm01-run-startup-cmd" {
  name                 = "${var.environment}-f5vm01-run-startup-cmd"
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
    Name        = "${var.environment}-f5vm01-startup-cmd"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = var.application
  }
}

resource "azurerm_virtual_machine_extension" "f5vm02-run-startup-cmd" {
  name                 = "${var.environment}-f5vm02-run-startup-cmd"
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
    Name        = "${var.environment}-f5vm02-startup-cmd"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = var.application
  }
}

# Run REST API for configuration
resource "local_file" "vm01_do_file" {
  content  = data.template_file.vm01_do_json.rendered
  filename = "${path.module}/${var.rest_vm01_do_file}"
}

resource "local_file" "vm02_do_file" {
  content  = data.template_file.vm02_do_json.rendered
  filename = "${path.module}/${var.rest_vm02_do_file}"
}

resource "local_file" "vm_as3_file" {
  content  = data.template_file.as3_json.rendered
  filename = "${path.module}/${var.rest_vm_as3_file}"
}

resource "local_file" "vm_ts_file" {
  content  = data.template_file.ts_json.rendered
  filename = "${path.module}/${var.rest_vm_ts_file}"
}

resource "local_file" "vm_failover_file" {
  content  = data.template_file.failover_json.rendered
  filename = "${path.module}/${var.rest_vm_failover_file}"
}

resource "null_resource" "f5vm01_DO" {
  depends_on = [azurerm_virtual_machine_extension.f5vm01-run-startup-cmd]
  # Running DO REST API
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -k -X ${var.rest_do_method} https://${azurerm_public_ip.vm01mgmtpip.ip_address}${var.rest_do_uri} -u ${var.uname}:${var.upassword} -d @${var.rest_vm01_do_file}
      x=1; while [ $x -le 30 ]; do STATUS=$(curl -s -k -X GET https://${azurerm_public_ip.vm01mgmtpip.ip_address}/mgmt/shared/declarative-onboarding/task -u ${var.uname}:${var.upassword}); if ( echo $STATUS | grep "OK" ); then break; fi; sleep 10; x=$(( $x + 1 )); done
      sleep 10
    EOF
  }
}

resource "null_resource" "f5vm02_DO" {
  depends_on = [azurerm_virtual_machine_extension.f5vm02-run-startup-cmd]
  # Running DO REST API
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -k -X ${var.rest_do_method} https://${azurerm_public_ip.vm02mgmtpip.ip_address}${var.rest_do_uri} -u ${var.uname}:${var.upassword} -d @${var.rest_vm02_do_file}
      x=1; while [ $x -le 30 ]; do STATUS=$(curl -s -k -X GET https://${azurerm_public_ip.vm02mgmtpip.ip_address}/mgmt/shared/declarative-onboarding/task -u ${var.uname}:${var.upassword}); if ( echo $STATUS | grep "OK" ); then break; fi; sleep 10; x=$(( $x + 1 )); done
      sleep 10
    EOF
  }
}

resource "null_resource" "f5vm01_TS" {
  depends_on = [null_resource.f5vm01_DO]
  # Running TS REST API
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -H 'Content-Type: application/json' -k -X POST https://${azurerm_public_ip.vm01mgmtpip.ip_address}${var.rest_ts_uri} -u ${var.uname}:${var.upassword} -d @${var.rest_vm_ts_file}
    EOF
  }
}

resource "null_resource" "f5vm02_TS" {
  depends_on = [null_resource.f5vm02_DO]
  # Running TS REST API
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -H 'Content-Type: application/json' -k -X POST https://${azurerm_public_ip.vm02mgmtpip.ip_address}${var.rest_ts_uri} -u ${var.uname}:${var.upassword} -d @${var.rest_vm_ts_file}
    EOF
  }
}

resource "null_resource" "f5vm01_CF" {
  depends_on = [null_resource.f5vm01_TS]
  # Running CF REST API
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -k -X POST https://${azurerm_public_ip.vm01mgmtpip.ip_address}${var.rest_CF_uri} -u ${var.uname}:${var.upassword} -d @${var.rest_vm_failover_file}
    EOF
  }
}

resource "null_resource" "f5vm02_CF" {
  depends_on = [null_resource.f5vm02_TS]
  # Running CF REST API
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -k -X POST https://${azurerm_public_ip.vm02mgmtpip.ip_address}${var.rest_CF_uri} -u ${var.uname}:${var.upassword} -d @${var.rest_vm_failover_file}
    EOF
  }
}

resource "null_resource" "f5vm_AS3" {
  depends_on = [null_resource.f5vm01_CF, null_resource.f5vm02_CF]
  # Running AS3 REST API
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -k -X ${var.rest_as3_method} https://${azurerm_public_ip.vm01mgmtpip.ip_address}${var.rest_as3_uri} -u ${var.uname}:${var.upassword} -d @${var.rest_vm_as3_file}
    EOF
  }
}
