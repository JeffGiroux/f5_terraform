# Create a Resource Group for the new Virtual Machine
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}_rg"
  location = "${var.location}"
}

# Create a Virtual Network within the Resource Group
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["${var.cidr}"]
  resource_group_name = "${azurerm_resource_group.main.name}"
  location            = "${azurerm_resource_group.main.location}"
}

# Create the Storage Account
resource "azurerm_storage_account" "mystorage" {
  name                = "${var.prefix}mystorage"
  resource_group_name = "${azurerm_resource_group.main.name}"
  location                 = "${azurerm_resource_group.main.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
    f5_cloud_failover_label = "${var.f5_cloud_failover_label}" 
  }
}

# Create Route Table
resource "azurerm_route_table" "udr" {
  name                          = "udr"
  location                      = "${azurerm_resource_group.main.location}"
  resource_group_name           = "${azurerm_resource_group.main.name}"
  disable_bgp_route_propagation = false

  route {
    name           = "route1"
    address_prefix = "${var.managed_route1}"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "${azurerm_network_interface.vm01-ext-nic.private_ip_address}"
  }

  tags = {
    f5_cloud_failover_label = "${var.f5_cloud_failover_label}"
    f5_self_ips = "${azurerm_network_interface.vm01-ext-nic.private_ip_address},${azurerm_network_interface.vm02-ext-nic.private_ip_address}"
  }
}

# Create the first Subnet within the Virtual Network
resource "azurerm_subnet" "Mgmt" {
  name                 = "Mgmt"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  address_prefix       = "${var.subnets["subnet1"]}"
}

# Create the second Subnet within the Virtual Network
resource "azurerm_subnet" "External" {
  name                 = "External"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  address_prefix       = "${var.subnets["subnet2"]}"
}

# Obtain Gateway IP for each Subnet
locals {
  depends_on = ["azurerm_subnet.Mgmt", "azurerm_subnet.External"]
  mgmt_gw    = "${cidrhost(azurerm_subnet.Mgmt.address_prefix, 1)}"
  ext_gw     = "${cidrhost(azurerm_subnet.External.address_prefix, 1)}"
}

# Create a Public IP for the Virtual Machines
resource "azurerm_public_ip" "vm01mgmtpip" {
  name                         = "${var.prefix}-vm01-mgmt-pip"
  location                     = "${azurerm_resource_group.main.location}"
  sku    		       = "Standard"
  zones			       = [1]
  resource_group_name          = "${azurerm_resource_group.main.name}"
  allocation_method = "Static"

  tags = {
    Name           = "${var.environment}-vm01-mgmt-public-ip"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
}

resource "azurerm_public_ip" "vm01selfpip" {
  name                         = "${var.prefix}-vm01-self-pip"
  location                     = "${azurerm_resource_group.main.location}"
  sku                          = "Standard"
  zones                        = [1]
  resource_group_name          = "${azurerm_resource_group.main.name}"
  allocation_method = "Static"

  tags = {
    Name           = "${var.environment}-vm01-self-public-ip"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
}

resource "azurerm_public_ip" "vm02mgmtpip" {
  name                         = "${var.prefix}-vm02-mgmt-pip"
  location                     = "${azurerm_resource_group.main.location}"
  sku                          = "Standard"
  zones			       = [2]
  resource_group_name          = "${azurerm_resource_group.main.name}"
  allocation_method = "Static"

  tags = {
    Name           = "${var.environment}-vm02-mgmt-public-ip"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
}

resource "azurerm_public_ip" "vm02selfpip" {
  name                         = "${var.prefix}-vm02-self-pip"
  location                     = "${azurerm_resource_group.main.location}"
  sku                          = "Standard"
  zones                        = [2]
  resource_group_name          = "${azurerm_resource_group.main.name}"
  allocation_method = "Static"

  tags = {
    Name           = "${var.environment}-vm02-self-public-ip"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
}


resource "azurerm_public_ip" "pubvippip" {
  name                         = "${var.prefix}-pubvip-pip"
  location                     = "${azurerm_resource_group.main.location}"
  sku                          = "Standard"
  zones                        = [1]
  resource_group_name          = "${azurerm_resource_group.main.name}"
  allocation_method = "Static"

  tags = {
    Name           = "${var.environment}-pubvip-public-ip"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
}

# Create a Network Security Group with some rules
resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-nsg"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

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
    name                       = "allow_RDP"
    description                = "Allow RDP access"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_APP_HTTPS"
    description                = "Allow HTTPS access"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Name           = "${var.environment}-bigip-sg"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
}

# Create the first network interface card for Management 
resource "azurerm_network_interface" "vm01-mgmt-nic" {
  name                      = "${var.prefix}-mgmt0"
  location                  = "${azurerm_resource_group.main.location}"
  resource_group_name       = "${azurerm_resource_group.main.name}"
  network_security_group_id = "${azurerm_network_security_group.main.id}"

  ip_configuration {
    name                          = "primary"
    subnet_id                     = "${azurerm_subnet.Mgmt.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.f5vm01mgmt}"
    public_ip_address_id          = "${azurerm_public_ip.vm01mgmtpip.id}"
  }

  tags = {
    Name           = "${var.environment}-vm01-mgmt-int"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
}

resource "azurerm_network_interface" "vm02-mgmt-nic" {
  name                      = "${var.prefix}-mgmt1"
  location                  = "${azurerm_resource_group.main.location}"
  resource_group_name       = "${azurerm_resource_group.main.name}"
  network_security_group_id = "${azurerm_network_security_group.main.id}"

  ip_configuration {
    name                          = "primary"
    subnet_id                     = "${azurerm_subnet.Mgmt.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.f5vm02mgmt}"
    public_ip_address_id          = "${azurerm_public_ip.vm02mgmtpip.id}"
  }

  tags = {
    Name           = "${var.environment}-vm02-mgmt-int"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
}

# Create the second network interface card for External
resource "azurerm_network_interface" "vm01-ext-nic" {
  name                = "${var.prefix}-ext0"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  network_security_group_id = "${azurerm_network_security_group.main.id}"

  ip_configuration {
    name                          = "f5vm-self-ipconfig"
    subnet_id                     = "${azurerm_subnet.External.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.f5vm01ext}"
    primary			  = true
    public_ip_address_id          = "${azurerm_public_ip.vm01selfpip.id}"
  }

  ip_configuration {
    name                          = "${var.prefix}-ext-ipconfig0"
    subnet_id                     = "${azurerm_subnet.External.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.f5privatevip}"
  }

  ip_configuration {
    name                          = "${var.prefix}-ext-ipconfig1"
    subnet_id                     = "${azurerm_subnet.External.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.f5publicvip}"
    public_ip_address_id          = "${azurerm_public_ip.pubvippip.id}"
  }

  tags = {
    Name           = "${var.environment}-vm01-ext-int"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
    f5_cloud_failover_label = "${var.f5_cloud_failover_label}"
    f5_cloud_failover_nic_map = "${var.f5_cloud_failover_nic_map}"
  }
}

resource "azurerm_network_interface" "vm02-ext-nic" {
  name                = "${var.prefix}-ext1"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  network_security_group_id = "${azurerm_network_security_group.main.id}"

  ip_configuration {
    name                          = "f5vm-self-ipconfig"
    subnet_id                     = "${azurerm_subnet.External.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.f5vm02ext}"
    primary			  = true
    public_ip_address_id          = "${azurerm_public_ip.vm02selfpip.id}"
  }

  tags = {
    Name           = "${var.environment}-vm02-ext-int"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
    f5_cloud_failover_label = "${var.f5_cloud_failover_label}"
    f5_cloud_failover_nic_map = "${var.f5_cloud_failover_nic_map}"
  }
}

resource "azurerm_network_interface" "backend01-ext-nic" {
  name                = "${var.prefix}-backend01-ext-nic"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  network_security_group_id = "${azurerm_network_security_group.main.id}"

  ip_configuration {
    name                          = "primary"
    subnet_id                     = "${azurerm_subnet.External.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.backend01ext}"
    primary			  = true
  }

  tags = {
    Name           = "${var.environment}-backend01-ext-int"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "app1"
  }
}


# Setup Onboarding scripts
data "template_file" "vm_onboard" {
  template = "${file("${path.module}/onboard.tpl")}"

  vars = {
    uname        	  = "${var.uname}"
    upassword        	  = "${var.upassword}"
    DO_onboard_URL        = "${var.DO_onboard_URL}"
    AS3_URL		  = "${var.AS3_URL}"
    TS_URL                = "${var.TS_URL}"
    CF_URL		  = "${var.CF_URL}"
    libs_dir		  = "${var.libs_dir}"
    onboard_log		  = "${var.onboard_log}"
    mgmt_gw		  = "${local.mgmt_gw}"
  }
}

data "template_file" "vm01_do_json" {
  template = "${file("${path.module}/cluster.json")}"

  vars = {
    #Uncomment the following line for BYOL
    #local_sku	    = "${var.license1}"

    host1	    = "${var.host1_name}"
    host2	    = "${var.host2_name}"
    local_host      = "${var.host1_name}"
    local_selfip    = "${var.f5vm01ext}"
    remote_host	    = "${var.host2_name}"
    remote_selfip   = "${var.f5vm02ext}"
    gateway	    = "${local.ext_gw}"
    dns_server	    = "${var.dns_server}"
    ntp_server	    = "${var.ntp_server}"
    timezone	    = "${var.timezone}"
    admin_user      = "${var.uname}"
    admin_password  = "${var.upassword}"
  }
}

data "template_file" "vm02_do_json" {
  template = "${file("${path.module}/cluster.json")}"

  vars = {
    #Uncomment the following line for BYOL
    #local_sku      = "${var.license2}"

    host1           = "${var.host1_name}"
    host2           = "${var.host2_name}"
    local_host      = "${var.host2_name}"
    local_selfip    = "${var.f5vm02ext}"
    remote_host     = "${var.host1_name}"
    remote_selfip   = "${var.f5vm01ext}"
    gateway         = "${local.ext_gw}"
    dns_server      = "${var.dns_server}"
    ntp_server      = "${var.ntp_server}"
    timezone        = "${var.timezone}"
    admin_user      = "${var.uname}"
    admin_password  = "${var.upassword}"
  }
}

data "template_file" "as3_json" {
  template = "${file("${path.module}/as3.json")}"

  vars = {
    rg_name	    = "${azurerm_resource_group.main.name}"
    subscription_id = "${var.SP["subscription_id"]}"
    tenant_id	    = "${var.SP["tenant_id"]}"
    client_id	    = "${var.SP["client_id"]}"
    client_secret   = "${var.SP["client_secret"]}"
    publicvip	    = "${var.f5publicvip}"
    privatevip      = "${var.f5privatevip}"
  }
}

data "template_file" "failover_json" {
  template = "${file("${path.module}/failover.json")}"

  vars = {
    f5_cloud_failover_label = "${var.f5_cloud_failover_label}"
    managed_route1 = "${var.managed_route1}"
  }
}


# Create F5 BIGIP VMs
resource "azurerm_virtual_machine" "f5vm01" {
  name                         = "${var.prefix}-f5vm01"
  location                     = "${azurerm_resource_group.main.location}"
  zones			       = [1]
  resource_group_name          = "${azurerm_resource_group.main.name}"
  primary_network_interface_id = "${azurerm_network_interface.vm01-mgmt-nic.id}"
  network_interface_ids        = ["${azurerm_network_interface.vm01-mgmt-nic.id}", "${azurerm_network_interface.vm01-ext-nic.id}"]
  vm_size                      = "${var.instance_type}"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
   delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
   delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "f5-networks"
    offer     = "${var.product}"
    sku       = "${var.image_name}"
    version   = "${var.bigip_version}"
  }

  storage_os_disk {
    name              = "${var.prefix}vm01-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.prefix}vm01"
    admin_username = "${var.uname}"
    admin_password = "${var.upassword}"
    custom_data    = "${data.template_file.vm_onboard.rendered}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  plan {
    name          = "${var.image_name}"
    publisher     = "f5-networks"
    product       = "${var.product}"
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.mystorage.primary_blob_endpoint}"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Name           = "${var.environment}-f5vm01"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
}

resource "azurerm_virtual_machine" "f5vm02" {
  name                         = "${var.prefix}-f5vm02"
  location                     = "${azurerm_resource_group.main.location}"
  zones			       = [2]
  resource_group_name          = "${azurerm_resource_group.main.name}"
  primary_network_interface_id = "${azurerm_network_interface.vm02-mgmt-nic.id}"
  network_interface_ids        = ["${azurerm_network_interface.vm02-mgmt-nic.id}", "${azurerm_network_interface.vm02-ext-nic.id}"]
  vm_size                      = "${var.instance_type}"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "f5-networks"
    offer     = "${var.product}"
    sku       = "${var.image_name}"
    version   = "${var.bigip_version}"
  }

  storage_os_disk {
    name              = "${var.prefix}vm02-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "${var.prefix}vm02"
    admin_username = "${var.uname}"
    admin_password = "${var.upassword}"
    custom_data    = "${data.template_file.vm_onboard.rendered}"
}

  os_profile_linux_config {
    disable_password_authentication = false
  }

  plan {
    name          = "${var.image_name}"
    publisher     = "f5-networks"
    product       = "${var.product}"
  }

  boot_diagnostics {
    enabled     = "true"
    storage_uri = "${azurerm_storage_account.mystorage.primary_blob_endpoint}"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Name           = "${var.environment}-f5vm02"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
}

# backend VM
resource "azurerm_virtual_machine" "backendvm" {
    name                  = "backendvm"
    location                     = "${azurerm_resource_group.main.location}"
    resource_group_name          = "${azurerm_resource_group.main.name}"

    network_interface_ids = ["${azurerm_network_interface.backend01-ext-nic.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "backendOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "backend01"
        admin_username = "azureuser"
        admin_password = "${var.upassword}"
        custom_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io
              docker run -d -p 80:80 --net=host --restart unless-stopped vulnerables/web-dvwa
              EOF
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

  tags = {
    Name           = "${var.environment}-backend01"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
  }
}


# Configure VMs to use a system-assgined managed identity
data "azurerm_resource_group" "main" {
   name		     = "${azurerm_resource_group.main.name}"
   depends_on        = ["azurerm_virtual_machine.f5vm01", "azurerm_virtual_machine.f5vm02"]
}

data "azurerm_subscription" "primary" {}

resource "azurerm_role_assignment" "f5vm01ra" {
  scope              = "${data.azurerm_resource_group.main.id}"
  role_definition_name = "Contributor"
  principal_id       = "${lookup(azurerm_virtual_machine.f5vm01.identity[0], "principal_id")}"
}

resource "azurerm_role_assignment" "f5vm02ra" {
  scope              = "${data.azurerm_resource_group.main.id}"
  role_definition_name = "Contributor"
  principal_id       = "${lookup(azurerm_virtual_machine.f5vm02.identity[0], "principal_id")}"
}


# Run Startup Script
resource "azurerm_virtual_machine_extension" "f5vm01-run-startup-cmd" {
  name                 = "${var.environment}-f5vm01-run-startup-cmd"
  depends_on           = ["azurerm_virtual_machine.f5vm01", "azurerm_virtual_machine.backendvm"]
  location             = "${var.region}"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  virtual_machine_name = "${azurerm_virtual_machine.f5vm01.name}"
  publisher            = "Microsoft.OSTCExtensions"
  type                 = "CustomScriptForLinux"
  type_handler_version = "1.2"
  # publisher            = "Microsoft.Azure.Extensions"
  # type                 = "CustomScript"
  # type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "bash /var/lib/waagent/CustomData"
    }
  SETTINGS

  tags = {
    Name           = "${var.environment}-f5vm01-startup-cmd"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
}

resource "azurerm_virtual_machine_extension" "f5vm02-run-startup-cmd" {
  name                 = "${var.environment}-f5vm02-run-startup-cmd"
  depends_on           = ["azurerm_virtual_machine.f5vm02", "azurerm_virtual_machine.backendvm"]
  location             = "${var.region}"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  virtual_machine_name = "${azurerm_virtual_machine.f5vm02.name}"
  publisher            = "Microsoft.OSTCExtensions"
  type                 = "CustomScriptForLinux"
  type_handler_version = "1.2"
  # publisher            = "Microsoft.Azure.Extensions"
  # type                 = "CustomScript"
  # type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "bash /var/lib/waagent/CustomData"
    }
  SETTINGS

  tags = {
    Name           = "${var.environment}-f5vm02-startup-cmd"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
}

# Run REST API for configuration
resource "local_file" "vm01_do_file" {
  content     = "${data.template_file.vm01_do_json.rendered}"
  filename    = "${path.module}/${var.rest_vm01_do_file}"
}

resource "local_file" "vm02_do_file" {
  content     = "${data.template_file.vm02_do_json.rendered}"
  filename    = "${path.module}/${var.rest_vm02_do_file}"
}

resource "local_file" "vm_as3_file" {
  content     = "${data.template_file.as3_json.rendered}"
  filename    = "${path.module}/${var.rest_vm_as3_file}"
}

resource "local_file" "vm_failover_file" {
  content     = "${data.template_file.failover_json.rendered}"
  filename    = "${path.module}/${var.rest_vm_failover_file}"
}



resource "null_resource" "f5vm01_DO" {
  depends_on    = ["azurerm_virtual_machine_extension.f5vm01-run-startup-cmd"]
  # Running DO REST API
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -k -X ${var.rest_do_method} https://${data.azurerm_public_ip.vm01mgmtpip.ip_address}${var.rest_do_uri} -u ${var.uname}:${var.upassword} -d @${var.rest_vm01_do_file}
      x=1; while [ $x -le 30 ]; do STATUS=$(curl -k -X GET https://${data.azurerm_public_ip.vm01mgmtpip.ip_address}/mgmt/shared/declarative-onboarding/task -u ${var.uname}:${var.upassword}); if ( echo $STATUS | grep "OK" ); then break; fi; sleep 10; x=$(( $x + 1 )); done
      sleep 120
    EOF
  }
}


resource "null_resource" "f5vm02_DO" {
  depends_on    = ["azurerm_virtual_machine_extension.f5vm02-run-startup-cmd"]
  # Running DO REST API
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -k -X ${var.rest_do_method} https://${data.azurerm_public_ip.vm02mgmtpip.ip_address}${var.rest_do_uri} -u ${var.uname}:${var.upassword} -d @${var.rest_vm02_do_file}
      x=1; while [ $x -le 30 ]; do STATUS=$(curl -k -X GET https://${data.azurerm_public_ip.vm02mgmtpip.ip_address}/mgmt/shared/declarative-onboarding/task -u ${var.uname}:${var.upassword}); if ( echo $STATUS | grep "OK" ); then break; fi; sleep 10; x=$(( $x + 1 )); done
      sleep 120
    EOF
  }
}

resource "null_resource" "f5vm01_CF" {
  depends_on    = ["null_resource.f5vm01_DO"]
  # Running CF REST API
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -k -X POST https://${data.azurerm_public_ip.vm01mgmtpip.ip_address}${var.rest_CF_uri} -u ${var.uname}:${var.upassword} -d @${var.rest_vm_failover_file}
    sleep 30
    EOF
  }
}

resource "null_resource" "f5vm02_CF" {
  depends_on    = ["null_resource.f5vm02_DO"]
  # Running CF REST API
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -k -X POST https://${data.azurerm_public_ip.vm02mgmtpip.ip_address}${var.rest_CF_uri} -u ${var.uname}:${var.upassword} -d @${var.rest_vm_failover_file}
    EOF
  }
}


resource "null_resource" "f5vm_AS3" {
  depends_on    = ["null_resource.f5vm01_CF"]
  # Running AS3 REST API
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -k -X ${var.rest_as3_method} https://${data.azurerm_public_ip.vm01mgmtpip.ip_address}${var.rest_as3_uri} -u ${var.uname}:${var.upassword} -d @${var.rest_vm_as3_file}
    EOF
  }
}

## OUTPUTS ###
data "azurerm_public_ip" "vm01mgmtpip" {
  name                = "${azurerm_public_ip.vm01mgmtpip.name}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  depends_on          = ["azurerm_virtual_machine_extension.f5vm01-run-startup-cmd"]
}
data "azurerm_public_ip" "vm02mgmtpip" {
  name                = "${azurerm_public_ip.vm02mgmtpip.name}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  depends_on          = ["azurerm_virtual_machine_extension.f5vm02-run-startup-cmd"]
}
data "azurerm_public_ip" "pubvippip" {
  name                = "${azurerm_public_ip.pubvippip.name}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  depends_on          = ["azurerm_virtual_machine_extension.f5vm01-run-startup-cmd"]
}


output "sg_id" { value = "${azurerm_network_security_group.main.id}" }
output "sg_name" { value = "${azurerm_network_security_group.main.name}" }
output "mgmt_subnet_gw" { value = "${local.mgmt_gw}" }
output "ext_subnet_gw" { value = "${local.ext_gw}" }
output "Public_VIP_pip" { value = "${data.azurerm_public_ip.pubvippip.ip_address}" }

output "f5vm01_id" { value = "${azurerm_virtual_machine.f5vm01.id}"  }
output "f5vm01_mgmt_private_ip" { value = "${azurerm_network_interface.vm01-mgmt-nic.private_ip_address}" }
output "f5vm01_mgmt_public_ip" { value = "${data.azurerm_public_ip.vm01mgmtpip.ip_address}" }
output "f5vm01_ext_private_ip" { value = "${azurerm_network_interface.vm01-ext-nic.private_ip_address}" }

output "f5vm02_id" { value = "${azurerm_virtual_machine.f5vm02.id}"  }
output "f5vm02_mgmt_private_ip" { value = "${azurerm_network_interface.vm02-mgmt-nic.private_ip_address}" }
output "f5vm02_mgmt_public_ip" { value = "${data.azurerm_public_ip.vm02mgmtpip.ip_address}" }
output "f5vm02_ext_private_ip" { value = "${azurerm_network_interface.vm02-ext-nic.private_ip_address}" }
