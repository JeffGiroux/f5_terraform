# Create a Resource Group for the new Virtual Machine
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}_rg"
  location = "${var.location}"
}

# Create a Virtual Network for Private DMZ
resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["${var.cidr}"]
  resource_group_name = "${azurerm_resource_group.main.name}"
  location            = "${azurerm_resource_group.main.location}"
}

# Create a gwsubnet subnet for Transit Gateway
resource "azurerm_subnet" "GatewaySubnet" {
  name                 = "GatewaySubnet"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  address_prefix       = "${var.subnets["gwsubnet"]}"
}

# Create the first Subnet within the Private DMZ Virtual Network
resource "azurerm_subnet" "Mgmt" {
  name                 = "Mgmt"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  address_prefix       = "${var.subnets["subnet1"]}"
}

# Create the second Subnet within the Private DMZ Virtual Network
resource "azurerm_subnet" "External" {
  name                 = "External"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  address_prefix       = "${var.subnets["subnet2"]}"
}

# Create a Public IP for the Virtual Machines
resource "azurerm_public_ip" "vm01mgmtpip" {
  name                         = "${var.prefix}-vm01-mgmt-pip"
  location                     = "${azurerm_resource_group.main.location}"
  resource_group_name          = "${azurerm_resource_group.main.name}"
  allocation_method = "Dynamic"

  tags {
    Name           = "${var.environment}-vm01-mgmt-public-ip"
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
  resource_group_name          = "${azurerm_resource_group.main.name}"
  allocation_method = "Dynamic"

  tags {
    Name           = "${var.environment}-vm02-mgmt-public-ip"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
}

resource "azurerm_public_ip" "tgwpip" {
  name                         = "${var.prefix}-tgw-pip"
  location                     = "${azurerm_resource_group.main.location}"
  resource_group_name          = "${azurerm_resource_group.main.name}"
  allocation_method = "Dynamic"

  tags {
    Name           = "${var.environment}-tgw-public-ip"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
}

# Create Local Network Gateway
resource "azurerm_local_network_gateway" "onpremise1" {
  name                = "onpremise1"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  gateway_address     = "${var.onpremsite1["publicip"]}"
  address_space       = ["${var.onpremsite1["addrspace1"]}", "${var.onpremsite1["addrspace2"]}"]
}

# Create Azure VPN Gateway
resource "azurerm_virtual_network_gateway" "site1" {
  name                = "site1"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  depends_on         = ["azurerm_public_ip.tgwpip"]

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "VpnGw1"

  ip_configuration {
    public_ip_address_id          = "${azurerm_public_ip.tgwpip.id}"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = "${azurerm_subnet.GatewaySubnet.id}"
  }
}

# Connect to On-prem Site1
resource "azurerm_virtual_network_gateway_connection" "onpremise1" {
  name                = "onpremise1"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  type                       = "IPsec"
  virtual_network_gateway_id = "${azurerm_virtual_network_gateway.site1.id}"
  local_network_gateway_id   = "${azurerm_local_network_gateway.onpremise1.id}"

  shared_key = "${var.onpremsite1["sharekey"]}"

}

# Create a custom Route Table for Gateway Subnet
resource "azurerm_route_table" "gwrt" {
  name                          = "gwrt"
  location                      = "${azurerm_resource_group.main.location}"
  resource_group_name           = "${azurerm_resource_group.main.name}"
  disable_bgp_route_propagation = false

  # This route is using Azure LB IP address as the next hop
  route {
    name           = "route1"
    # This route is configured depending on the specific usecase
    address_prefix = "20.90.0.0/16"
    next_hop_type  = "VirtualAppliance"
    next_hop_in_ip_address = "${var.lb_ip}"
  }

  tags {
    environment = "Production"
  }
}

resource "azurerm_subnet_route_table_association" "gwrt-GWS" {
  subnet_id      = "${azurerm_subnet.GatewaySubnet.id}"
  route_table_id = "${azurerm_route_table.gwrt.id}"
}

# Obtain Gateway IP for each Private DMZ Subnet
locals {
  depends_on = ["azurerm_subnet.Mgmt", "azurerm_subnet.External"]
  mgmt_gw    = "${cidrhost(azurerm_subnet.Mgmt.address_prefix, 1)}"
  ext_gw     = "${cidrhost(azurerm_subnet.External.address_prefix, 1)}"
}

# Create Availability Set
resource "azurerm_availability_set" "avset" {
  name                         = "${var.prefix}avset"
  location                     = "${azurerm_resource_group.main.location}"
  resource_group_name          = "${azurerm_resource_group.main.name}"
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}

# Create Azure LB
resource "azurerm_lb" "lb" {
  name                = "${var.prefix}lb"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    subnet_id		 = "${azurerm_subnet.External.id}"
    private_ip_address_allocation = "Static"
    private_ip_address	 = "${var.lb_ip}"
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  name                = "BackendPool1"
  resource_group_name = "${azurerm_resource_group.main.name}"
  loadbalancer_id     = "${azurerm_lb.lb.id}"
}

resource "azurerm_lb_probe" "lb_probe" {
  resource_group_name = "${azurerm_resource_group.main.name}"
  loadbalancer_id     = "${azurerm_lb.lb.id}"
  name                = "tcpProbe"
  protocol            = "tcp"
  port                = 8443
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "lb_rule" {
  name                           = "LBRule"
  resource_group_name            = "${azurerm_resource_group.main.name}"
  loadbalancer_id                = "${azurerm_lb.lb.id}"
  protocol                       = "tcp"
  frontend_port                  = 443
  backend_port                   = 8443
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  enable_floating_ip             = false
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.backend_pool.id}"
  idle_timeout_in_minutes        = 5
  probe_id                       = "${azurerm_lb_probe.lb_probe.id}"
  depends_on                     = ["azurerm_lb_probe.lb_probe"]
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

  tags {
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

  tags {
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

  tags {
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
  name                = "${var.prefix}-vm01-ext-nic"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
  network_security_group_id = "${azurerm_network_security_group.main.id}"
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

  tags {
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

  tags {
    Name           = "${var.environment}-vm01-ext-int"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }
}

# Associate the Network Interface to the BackendPool
resource "azurerm_network_interface_backend_address_pool_association" "bpool_assc_vm01" {
  network_interface_id    = "${azurerm_network_interface.vm01-ext-nic.id}"
  ip_configuration_name   = "secondary"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.backend_pool.id}"
  depends_on          = ["azurerm_lb_backend_address_pool.backend_pool", "azurerm_network_interface.vm01-ext-nic"]
}

resource "azurerm_network_interface_backend_address_pool_association" "bpool_assc_vm02" {
  network_interface_id    = "${azurerm_network_interface.vm02-ext-nic.id}"
  ip_configuration_name   = "secondary"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.backend_pool.id}"
  depends_on          = ["azurerm_lb_backend_address_pool.backend_pool", "azurerm_network_interface.vm02-ext-nic"]
}

# Setup Onboarding scripts
data "template_file" "vm_onboard" {
  template = "${file("${path.module}/onboard.tpl")}"

  vars {
    uname        	  = "${var.uname}"
    upassword        	  = "${var.upassword}"
    DO_onboard_URL        = "${var.DO_onboard_URL}"
    AS3_URL		  = "${var.AS3_URL}"
    libs_dir		  = "${var.libs_dir}"
    onboard_log		  = "${var.onboard_log}"
  }
}

data "template_file" "vm01_do_json" {
  template = "${file("${path.module}/cluster.json")}"

  vars {
    #Uncomment the following line for BYOL
    #local_sku	    = "${var.license1}"

    host1	    = "${var.host1_name}"
    host2           = "${var.host2_name}"
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

  vars {
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
}

# Create F5 BIGIP VMs
resource "azurerm_virtual_machine" "f5vm01" {
  name                         = "${var.prefix}-f5vm01"
  location                     = "${azurerm_resource_group.main.location}"
  resource_group_name          = "${azurerm_resource_group.main.name}"
  primary_network_interface_id = "${azurerm_network_interface.vm01-mgmt-nic.id}"
  network_interface_ids        = ["${azurerm_network_interface.vm01-mgmt-nic.id}", "${azurerm_network_interface.vm01-ext-nic.id}"]
  vm_size                      = "${var.instance_type}"
  availability_set_id          = "${azurerm_availability_set.avset.id}"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

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

  tags {
    Name           = "${var.environment}-f5vm01"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }

  provisioner "file" {
    content     = "${data.template_file.vm01_do_json.rendered}"
    destination = "/var/tmp/vm_do.json"
    connection {
      user	= "${var.uname}"
      password	= "${var.upassword}"
      agent = false
    }
  }

  provisioner "file" {
    content     = "${data.template_file.as3_json.rendered}"
    destination = "/var/tmp/as3.json"
    connection {
      user      = "${var.uname}"
      password  = "${var.upassword}"
      agent = false
    }
  }
}

resource "azurerm_virtual_machine" "f5vm02" {
  name                         = "${var.prefix}-f5vm02"
  location                     = "${azurerm_resource_group.main.location}"
  resource_group_name          = "${azurerm_resource_group.main.name}"
  primary_network_interface_id = "${azurerm_network_interface.vm02-mgmt-nic.id}"
  network_interface_ids        = ["${azurerm_network_interface.vm02-mgmt-nic.id}", "${azurerm_network_interface.vm02-ext-nic.id}"]
  vm_size                      = "${var.instance_type}"
  availability_set_id          = "${azurerm_availability_set.avset.id}"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

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

  tags {
    Name           = "${var.environment}-f5vm02"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
  }

  provisioner "file" {
    content     = "${data.template_file.vm02_do_json.rendered}"
    destination = "/var/tmp/vm_do.json"
    connection {
      user = "${var.uname}"
      password = "${var.upassword}"
      agent = false
    }
  }

  provisioner "file" {
    content     = "${data.template_file.as3_json.rendered}"
    destination = "/var/tmp/as3.json"
    connection {
      user = "${var.uname}"
      password = "${var.upassword}"
      agent = false
    }
  }
}


# Run Startup Script
resource "azurerm_virtual_machine_extension" "f5vm01-run-startup-cmd" {
  name                 = "${var.environment}-f5vm01-run-startup-cmd"
  location             = "${var.region}"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  virtual_machine_name = "${azurerm_virtual_machine.f5vm01.name}"
  publisher            = "Microsoft.OSTCExtensions"
  type                 = "CustomScriptForLinux"
  type_handler_version = "1.2"
  depends_on           = ["azurerm_virtual_machine.f5vm01"]
  # publisher            = "Microsoft.Azure.Extensions"
  # type                 = "CustomScript"
  # type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "bash /var/lib/waagent/CustomData"
    }
  SETTINGS

  tags {
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
  location             = "${var.region}"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  virtual_machine_name = "${azurerm_virtual_machine.f5vm02.name}"
  publisher            = "Microsoft.OSTCExtensions"
  type                 = "CustomScriptForLinux"
  type_handler_version = "1.2"
  depends_on           = ["azurerm_virtual_machine_extension.f5vm01-run-startup-cmd"]
  # publisher            = "Microsoft.Azure.Extensions"
  # type                 = "CustomScript"
  # type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "bash /var/lib/waagent/CustomData"
    }
  SETTINGS

  tags {
    Name           = "${var.environment}-f5vm02-startup-cmd"
    environment    = "${var.environment}"
    owner          = "${var.owner}"
    group          = "${var.group}"
    costcenter     = "${var.costcenter}"
    application    = "${var.application}"
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
data "azurerm_public_ip" "tgwpip" {
  name                = "${azurerm_public_ip.tgwpip.name}"
  resource_group_name = "${azurerm_resource_group.main.name}"
}

output "sg_id" { value = "${azurerm_network_security_group.main.id}" }
output "sg_name" { value = "${azurerm_network_security_group.main.name}" }
output "mgmt_subnet_gw" { value = "${local.mgmt_gw}" }
output "ext_subnet_gw" { value = "${local.ext_gw}" }
output "tgwpip" { value = "${data.azurerm_public_ip.tgwpip.ip_address}" }

output "f5vm01_id" { value = "${azurerm_virtual_machine.f5vm01.id}"  }
output "f5vm01_mgmt_private_ip" { value = "${azurerm_network_interface.vm01-mgmt-nic.private_ip_address}" }
output "f5vm01_mgmt_public_ip" { value = "${data.azurerm_public_ip.vm01mgmtpip.ip_address}" }
output "f5vm01_ext_private_ip" { value = "${azurerm_network_interface.vm01-ext-nic.private_ip_address}" }

output "f5vm02_id" { value = "${azurerm_virtual_machine.f5vm02.id}"  }
output "f5vm02_mgmt_private_ip" { value = "${azurerm_network_interface.vm02-mgmt-nic.private_ip_address}" }
output "f5vm02_mgmt_public_ip" { value = "${data.azurerm_public_ip.vm02mgmtpip.ip_address}" }
output "f5vm02_ext_private_ip" { value = "${azurerm_network_interface.vm02-ext-nic.private_ip_address}" }
