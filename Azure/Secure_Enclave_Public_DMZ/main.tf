# Create a Resource Group for the new Virtual Machine
resource "azurerm_resource_group" "main" {
  name			= "${var.prefix}_rg"
  location = "${var.location}"
}

# Create Log Analytic Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                  = "${var.prefix}-law"
  sku                   = "PerNode"
  retention_in_days     = 300
  resource_group_name   = "${azurerm_resource_group.main.name}"
  location              = "${azurerm_resource_group.main.location}"
}

# Create a Virtual Network within the Resource Group
resource "azurerm_virtual_network" "main" {
  name			= "${var.prefix}-hub"
  address_space		= ["${var.cidr}"]
  resource_group_name	= "${azurerm_resource_group.main.name}"
  location		= "${azurerm_resource_group.main.location}"
}

# Create a Virtual Network within the Resource Group
resource "azurerm_virtual_network" "spoke" {
  name                  = "${var.prefix}-spoke"
  address_space         = ["${var.app-cidr}"]
  resource_group_name   = "${azurerm_resource_group.main.name}"
  location              = "${azurerm_resource_group.main.location}"
}

# Create the Mgmt Subnet within the Hub Virtual Network
resource "azurerm_subnet" "Mgmt" {
  name			= "Mgmt"
  virtual_network_name	= "${azurerm_virtual_network.main.name}"
  resource_group_name	= "${azurerm_resource_group.main.name}"
  address_prefix	= "${var.subnets["subnet1"]}"
}

# Create the External Subnet within the Hub Virtual Network
resource "azurerm_subnet" "External" {
  name			= "External"
  virtual_network_name	= "${azurerm_virtual_network.main.name}"
  resource_group_name	= "${azurerm_resource_group.main.name}"
  address_prefix	= "${var.subnets["subnet2"]}"
}

# Create the App1 Subnet within the Spoke Virtual Network
resource "azurerm_subnet" "App1" {
  name                  = "App1"
  virtual_network_name  = "${azurerm_virtual_network.spoke.name}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  address_prefix        = "${var.app-subnets["subnet1"]}"
}

# Obtain Gateway IP for each Subnet
locals {
  depends_on		= ["azurerm_subnet.Mgmt", "azurerm_subnet.External"]
  mgmt_gw		= "${cidrhost(azurerm_subnet.Mgmt.address_prefix, 1)}"
  ext_gw		= "${cidrhost(azurerm_subnet.External.address_prefix, 1)}"
  app1_gw                = "${cidrhost(azurerm_subnet.App1.address_prefix, 1)}"
}

# Create Network Peerings
resource "azurerm_virtual_network_peering" "HubToSpoke" {
  name                      = "HubToSpoke"
  depends_on                = ["azurerm_virtual_machine.backendvm"]
  resource_group_name       = "${azurerm_resource_group.main.name}"
  virtual_network_name      = "${azurerm_virtual_network.main.name}"
  remote_virtual_network_id = "${azurerm_virtual_network.spoke.id}"
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "SpokeToHub" {
  name                      = "HubToSpoke"
  depends_on                = ["azurerm_virtual_machine.backendvm"]
  resource_group_name       = "${azurerm_resource_group.main.name}"
  virtual_network_name      = "${azurerm_virtual_network.spoke.name}"
  remote_virtual_network_id = "${azurerm_virtual_network.main.id}"
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# Create a Public IP for the Virtual Machines
resource "azurerm_public_ip" "vm01mgmtpip" {
  name			= "${var.prefix}-vm01-mgmt-pip"
  location		= "${azurerm_resource_group.main.location}"
  resource_group_name	= "${azurerm_resource_group.main.name}"
  allocation_method	= "Dynamic"

  tags = {
    Name		= "${var.environment}-vm01-mgmt-public-ip"
    environment		= "${var.environment}"
    owner		= "${var.owner}"
    group		= "${var.group}"
    costcenter		= "${var.costcenter}"
    application		= "${var.application}"
  }
}

resource "azurerm_public_ip" "vm02mgmtpip" {
  name			= "${var.prefix}-vm02-mgmt-pip"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  allocation_method	= "Dynamic"

  tags = {
    Name		= "${var.environment}-vm02-mgmt-public-ip"
    environment		= "${var.environment}"
    owner		= "${var.owner}"
    group		= "${var.group}"
    costcenter		= "${var.costcenter}"
    application		= "${var.application}"
  }
}


resource "azurerm_public_ip" "lbpip" {
  name                  = "${var.prefix}-lb-pip"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  allocation_method	= "Dynamic"
  domain_name_label     = "${var.prefix}lbpip"
}

# Create Availability Set
resource "azurerm_availability_set" "avset" {
  name                  = "${var.prefix}avset"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed               = true
}

# Create Azure LB
resource "azurerm_lb" "lb" {
  name                  = "${var.prefix}lb"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name	= "${azurerm_resource_group.main.name}"

  frontend_ip_configuration {
    name                = "LoadBalancerFrontEnd"
    public_ip_address_id	= "${azurerm_public_ip.lbpip.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  name                  = "BackendPool1"
  resource_group_name	= "${azurerm_resource_group.main.name}"
  loadbalancer_id       = "${azurerm_lb.lb.id}"
}

resource "azurerm_lb_probe" "lb_probe" {
  resource_group_name	= "${azurerm_resource_group.main.name}"
  loadbalancer_id       = "${azurerm_lb.lb.id}"
  name                  = "tcpProbe"
  protocol              = "tcp"
  port                  = 8443
  interval_in_seconds   = 5
  number_of_probes      = 2
}

resource "azurerm_lb_rule" "lb_rule1" {
  name                  = "LBRule1"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  loadbalancer_id       = "${azurerm_lb.lb.id}"
  protocol              = "tcp"
  frontend_port         = 443
  backend_port          = 8443
  frontend_ip_configuration_name	= "LoadBalancerFrontEnd"
  enable_floating_ip    	= false
  backend_address_pool_id	= "${azurerm_lb_backend_address_pool.backend_pool.id}"
  idle_timeout_in_minutes       = 5
  probe_id                      = "${azurerm_lb_probe.lb_probe.id}"
  depends_on                    = ["azurerm_lb_probe.lb_probe"]
}

resource "azurerm_lb_rule" "lb_rule2" {
  name                  = "LBRule2"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  loadbalancer_id       = "${azurerm_lb.lb.id}"
  protocol              = "tcp"
  frontend_port         = 80
  backend_port          = 80
  frontend_ip_configuration_name        = "LoadBalancerFrontEnd"
  enable_floating_ip            = false
  backend_address_pool_id       = "${azurerm_lb_backend_address_pool.backend_pool.id}"
  idle_timeout_in_minutes       = 5
  probe_id                      = "${azurerm_lb_probe.lb_probe.id}"
  depends_on                    = ["azurerm_lb_probe.lb_probe"]
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

# Create interfaces for the BIGIPs 
resource "azurerm_network_interface" "vm01-mgmt-nic" {
  name                      = "${var.prefix}-vm01-mgmt-nic"
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
  name                      = "${var.prefix}-vm02-mgmt-nic"
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

resource "azurerm_network_interface" "vm01-ext-nic" {
  name                = "${var.prefix}-vm01-ext-nic"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  network_security_group_id = "${azurerm_network_security_group.main.id}"
  enable_ip_forwarding	    = true
  depends_on          = ["azurerm_lb_backend_address_pool.backend_pool"]

  ip_configuration {
    name                          = "primary"
    subnet_id                     = "${azurerm_subnet.External.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.f5vm01ext}"
    primary			  = true
  }

  ip_configuration {
    name                          = "secondary"
    subnet_id                     = "${azurerm_subnet.External.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.f5vm01ext_sec}"
  }

  tags = {
    Name           = "${var.environment}-vm01-ext-int"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
}

resource "azurerm_network_interface" "vm02-ext-nic" {
  name                = "${var.prefix}-vm02-ext-nic"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  network_security_group_id = "${azurerm_network_security_group.main.id}"
  enable_ip_forwarding      = true
  depends_on          = ["azurerm_lb_backend_address_pool.backend_pool"]

  ip_configuration {
    name                          = "primary"
    subnet_id                     = "${azurerm_subnet.External.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.f5vm02ext}"
    primary			  = true
  }

  ip_configuration {
    name                          = "secondary"
    subnet_id                     = "${azurerm_subnet.External.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.f5vm02ext_sec}"
  }

  tags = {
    Name           = "${var.environment}-vm02-ext-int"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
}


# Create the Interface for the App server
resource "azurerm_network_interface" "backend01-ext-nic" {
  name                = "${var.prefix}-backend01-ext-nic"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  network_security_group_id = "${azurerm_network_security_group.main.id}"

  ip_configuration {
    name                          = "primary"
    subnet_id                     = "${azurerm_subnet.App1.id}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "${var.backend01ext}"
    primary			  = true
  }

  tags = {
    foo            = "bar"
  }
}

# Associate the Network Interface to the BackendPool
resource "azurerm_network_interface_backend_address_pool_association" "bpool_assc_vm01" {
  depends_on          = ["azurerm_lb_backend_address_pool.backend_pool", "azurerm_network_interface.vm01-ext-nic"]
  network_interface_id    = "${azurerm_network_interface.vm01-ext-nic.id}"
  ip_configuration_name   = "secondary"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.backend_pool.id}"
}

resource "azurerm_network_interface_backend_address_pool_association" "bpool_assc_vm02" {
  depends_on          = ["azurerm_lb_backend_address_pool.backend_pool", "azurerm_network_interface.vm02-ext-nic"]
  network_interface_id    = "${azurerm_network_interface.vm02-ext-nic.id}"
  ip_configuration_name   = "secondary"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.backend_pool.id}"
}

# Setup Onboarding scripts
data "template_file" "vm_onboard" {
  template = "${file("${path.module}/onboard.tpl")}"

  vars = {
    uname        	  = "${var.uname}"
    upassword        	  = "${var.upassword}"
    DO_onboard_URL        = "${var.DO_onboard_URL}"
    AS3_URL		  = "${var.AS3_URL}"
    TS_URL		  = "${var.TS_URL}"
    libs_dir		  = "${var.libs_dir}"
    onboard_log		  = "${var.onboard_log}"
  }
}

data "template_file" "vm01_do_json" {
  template = "${file("${path.module}/cluster.json")}"

  vars = {
    #Uncomment the following line for BYOL
    regkey	    = "${var.license1}"

    host1	    = "${var.host1_name}"
    host2	    = "${var.host2_name}"
    local_host      = "${var.host1_name}"
    local_selfip1   = "${var.f5vm01ext}"
    remote_selfip   = "${var.f5vm01ext}"
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
    regkey         = "${var.license2}"

    host1           = "${var.host1_name}"
    host2           = "${var.host2_name}"
    local_host      = "${var.host2_name}"
    local_selfip1   = "${var.f5vm02ext}"
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
    backendvm_ip    = "${var.backend01ext}"
    rg_name	    = "${azurerm_resource_group.main.name}"
    subscription_id = "${var.sp_subscription_id}"
    tenant_id	    = "${var.sp_tenant_id}"
    client_id	    = "${var.sp_client_id}"
    client_secret   = "${var.sp_client_secret}"
  }
}

data "template_file" "ts_json" {
  template = "${file("${path.module}/ts.json")}"
  depends_on           = ["azurerm_log_analytics_workspace.law"]
  vars = {
    law_id          = "${azurerm_log_analytics_workspace.law.workspace_id}"
    law_primkey     = "${azurerm_log_analytics_workspace.law.primary_shared_key}"
  }
}

# Create F5 BIGIP VMs
resource "azurerm_virtual_machine" "f5vm01" {
  name                         = "${var.prefix}-f5vm01"
  location                     = "${azurerm_resource_group.main.location}"
  depends_on                   = ["azurerm_virtual_machine.backendvm"]
  resource_group_name          = "${azurerm_resource_group.main.name}"
  primary_network_interface_id = "${azurerm_network_interface.vm01-mgmt-nic.id}"
  network_interface_ids        = ["${azurerm_network_interface.vm01-mgmt-nic.id}", "${azurerm_network_interface.vm01-ext-nic.id}"]
  vm_size                      = "${var.instance_type}"
  availability_set_id          = "${azurerm_availability_set.avset.id}"

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
    disk_size_gb      = "80"
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
  depends_on                   = ["azurerm_virtual_machine.backendvm"]
  resource_group_name          = "${azurerm_resource_group.main.name}"
  primary_network_interface_id = "${azurerm_network_interface.vm02-mgmt-nic.id}"
  network_interface_ids        = ["${azurerm_network_interface.vm02-mgmt-nic.id}", "${azurerm_network_interface.vm02-ext-nic.id}"]
  vm_size                      = "${var.instance_type}"
  availability_set_id          = "${azurerm_availability_set.avset.id}"

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
    disk_size_gb      = "80"
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
    vm_size               = "Standard_B1s"

    storage_os_disk {
        name              = "backendOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
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
    application    = "app1"
  }
}

# Run Startup Script
resource "azurerm_virtual_machine_extension" "f5vm01_run_startup_cmd" {
  name                 = "${var.environment}_f5vm01_run_startup_cmd"
  depends_on           = ["azurerm_virtual_machine.f5vm01"]
  location             = "${var.location}"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  virtual_machine_name = "${azurerm_virtual_machine.f5vm01.name}"
  publisher            = "Microsoft.OSTCExtensions"
  type                 = "CustomScriptForLinux"
  type_handler_version = "1.2"
  #publisher            = "Microsoft.Azure.Extensions"
  #type                 = "CustomScript"
  #type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "bash /var/lib/waagent/CustomData"
    }
  SETTINGS

  tags = {
    Name           = "${var.environment}_f5vm01_startup_cmd"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
}

resource "azurerm_virtual_machine_extension" "f5vm02_run_startup_cmd" {
  name                 = "${var.environment}_f5vm02-run_startup_cmd"
  depends_on           = ["azurerm_virtual_machine.f5vm02"]
  location             = "${var.location}"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  virtual_machine_name = "${azurerm_virtual_machine.f5vm02.name}"
  publisher            = "Microsoft.OSTCExtensions"
  type                 = "CustomScriptForLinux"
  type_handler_version = "1.2"
  #publisher            = "Microsoft.Azure.Extensions"
  #type                 = "CustomScript"
  #type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "bash /var/lib/waagent/CustomData"
    }
  SETTINGS

  tags = {
    Name           = "${var.environment}_f5vm02_startup_cmd"
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

resource "local_file" "vm_ts_file" {
  content     = "${data.template_file.ts_json.rendered}"
  filename    = "${path.module}/${var.rest_vm_ts_file}"
}

resource "null_resource" "f5vm01_DO" {
  depends_on	= ["azurerm_virtual_machine_extension.f5vm01_run_startup_cmd"]
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
  depends_on    = ["azurerm_virtual_machine_extension.f5vm02_run_startup_cmd"]
  # Running DO REST API
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -k -X ${var.rest_do_method} https://${data.azurerm_public_ip.vm02mgmtpip.ip_address}${var.rest_do_uri} -u ${var.uname}:${var.upassword} -d @${var.rest_vm02_do_file}
      x=1; while [ $x -le 30 ]; do STATUS=$(curl -k -X GET https://${data.azurerm_public_ip.vm01mgmtpip.ip_address}/mgmt/shared/declarative-onboarding/task -u ${var.uname}:${var.upassword}); if ( echo $STATUS | grep "OK" ); then break; fi; sleep 10; x=$(( $x + 1 )); done
      sleep 120
    EOF
  }
}

resource "null_resource" "f5vm01_TS" {
  depends_on    = ["null_resource.f5vm01_DO"]
  # Running CF REST API
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -H 'Content-Type: application/json' -k -X POST https://${data.azurerm_public_ip.vm01mgmtpip.ip_address}${var.rest_ts_uri} -u ${var.uname}:${var.upassword} -d @${var.rest_vm_ts_file}
    EOF
  }
}

resource "null_resource" "f5vm02_TS" {
  depends_on    = ["null_resource.f5vm02_DO"]
  # Running CF REST API
  provisioner "local-exec" {
    command = <<-EOF
      #!/bin/bash
      curl -H 'Content-Type: application/json' -k -X POST https://${data.azurerm_public_ip.vm02mgmtpip.ip_address}${var.rest_ts_uri} -u ${var.uname}:${var.upassword} -d @${var.rest_vm_ts_file}
    EOF
  }
}

resource "null_resource" "f5vm_AS3" {
  depends_on    = ["null_resource.f5vm01_DO", "null_resource.f5vm02_DO"]
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
  depends_on          = ["azurerm_virtual_machine.f5vm01"]
}
data "azurerm_public_ip" "vm02mgmtpip" {
  name                = "${azurerm_public_ip.vm02mgmtpip.name}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  depends_on          = ["azurerm_virtual_machine.f5vm02"]
}
data "azurerm_public_ip" "lbpip" {
  name                = "${azurerm_public_ip.lbpip.name}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  depends_on          = ["azurerm_virtual_machine.f5vm02"]
}

output "sg_id" { value = "${azurerm_network_security_group.main.id}" }
output "sg_name" { value = "${azurerm_network_security_group.main.name}" }
output "mgmt_subnet_gw" { value = "${local.mgmt_gw}" }
output "ext_subnet_gw" { value = "${local.ext_gw}" }
output "ALB_app1_pip" { value = "${data.azurerm_public_ip.lbpip.ip_address}" }

output "f5vm01_id" { value = "${azurerm_virtual_machine.f5vm01.id}"  }
output "f5vm01_mgmt_private_ip" { value = "${azurerm_network_interface.vm01-mgmt-nic.private_ip_address}" }
output "f5vm01_mgmt_public_ip" { value = "${data.azurerm_public_ip.vm01mgmtpip.ip_address}" }
output "f5vm01_ext_private_ip" { value = "${azurerm_network_interface.vm01-ext-nic.private_ip_address}" }

output "f5vm02_id" { value = "${azurerm_virtual_machine.f5vm02.id}"  }
output "f5vm02_mgmt_private_ip" { value = "${azurerm_network_interface.vm02-mgmt-nic.private_ip_address}" }
output "f5vm02_mgmt_public_ip" { value = "${data.azurerm_public_ip.vm02mgmtpip.ip_address}" }
output "f5vm02_ext_private_ip" { value = "${azurerm_network_interface.vm02-ext-nic.private_ip_address}" }
