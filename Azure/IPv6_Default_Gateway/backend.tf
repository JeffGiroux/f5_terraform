############################ NIC ############################

resource "azurerm_network_interface" "backend" {
  name                = format("%s-backend-nic-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_version    = "IPv4"
    private_ip_address_allocation = "Static"
    private_ip_address            = var.backendPrivateIp4
    primary                       = true
  }
  ip_configuration {
    name                          = "secondary"
    subnet_id                     = azurerm_subnet.backend.id
    private_ip_address_version    = "IPv6"
    private_ip_address_allocation = "Static"
    private_ip_address            = var.backendPrivateIp6
    primary                       = false
  }

  tags = {
    owner = var.owner
  }
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
resource "azurerm_linux_virtual_machine" "backend" {
  name                  = format("%s-backend-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.backend.id]
  size                  = var.backendInstanceType
  admin_username        = var.uname
  custom_data           = base64encode(local.backendvm_custom_data)
  admin_ssh_key {
    username   = var.uname
    public_key = var.ssh_key
  }
  os_disk {
    name                 = format("%s-backend-disk-%s", var.projectPrefix, random_id.buildSuffix.hex)
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts"
    version   = "latest"
  }
  tags = {
    owner = var.owner
  }
}
