# Azure Load Balancer

# Create Public IPs
resource "azurerm_public_ip" "lbpip" {
  name                = format("%s-lb-pip-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  domain_name_label   = "${var.projectPrefix}lbpip"
  tags = {
    owner = var.resourceOwner
  }
}

# Create Azure LB
resource "azurerm_lb" "lb" {
  name                = format("%s-lb-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  resource_group_name = azurerm_resource_group.main.name

  frontend_ip_configuration {
    name                 = "LoadBalancerFrontEnd"
    public_ip_address_id = azurerm_public_ip.lbpip.id
  }
  tags = {
    owner = var.resourceOwner
  }
}

# Create backend pool
resource "azurerm_lb_backend_address_pool" "backend_pool" {
  name            = "BackendPool1"
  loadbalancer_id = azurerm_lb.lb.id
}

# Create health probe
resource "azurerm_lb_probe" "lb_probe" {
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "tcpProbe"
  protocol            = "Tcp"
  port                = 80
  interval_in_seconds = 5
  number_of_probes    = 2
}

# Create frontend LB rule
resource "azurerm_lb_rule" "lb_rule1" {
  name                           = "LBRule1"
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "LoadBalancerFrontEnd"
  enable_floating_ip             = false
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pool.id]
  idle_timeout_in_minutes        = 5
  probe_id                       = azurerm_lb_probe.lb_probe.id
}
