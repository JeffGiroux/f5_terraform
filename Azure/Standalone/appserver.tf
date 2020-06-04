# Backend VM - web server running DVWA

# Create NIC
resource "azurerm_network_interface" "backend01-ext-nic" {
  name                = "${var.prefix}-backend01-ext-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.External.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.backend01ext
    primary                       = true
  }

  tags = {
    Name        = "${var.environment}-backend01-ext-int"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
    application = "app1"
  }
}

# Associate network security groups with NICs
resource "azurerm_network_interface_security_group_association" "backend01-ext-nsg" {
  network_interface_id      = azurerm_network_interface.backend01-ext-nic.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# Setup Onboarding scripts
locals {
  backendvm_custom_data = <<EOF
#!/bin/bash
apt-get update -y
apt-get install -y docker.io
docker run -d -p 80:80 --net=host --restart unless-stopped vulnerables/web-dvwa
EOF
}

# Create backend VM
resource "azurerm_linux_virtual_machine" "backendvm" {
  name                            = "backendvm"
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  network_interface_ids           = [azurerm_network_interface.backend01-ext-nic.id]
  size                            = "Standard_B1ms"
  admin_username                  = var.uname
  admin_password                  = var.upassword
  disable_password_authentication = false
  computer_name                   = "backend01"
  custom_data                     = base64encode(local.backendvm_custom_data)

  os_disk {
    name                 = "backendOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  tags = {
    Name        = "${var.environment}-backend01"
    environment = var.environment
    owner       = var.owner
    group       = var.group
    costcenter  = var.costcenter
  }
}
