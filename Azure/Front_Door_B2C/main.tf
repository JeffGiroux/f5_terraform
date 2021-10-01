# Main

# Terraform Version Pinning
terraform {
  required_version = "~> 0.14"
  required_providers {
    azurerm = "~> 2"
  }
}

# Azure Provider
provider "azurerm" {
  features {}
}

############################ Resource Group ############################

resource "azurerm_resource_group" "main" {
  name     = format("%s-rg-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location = var.azureLocation
  tags = {
    owner = var.resourceOwner
  }
}

############################ Front Door ############################

resource "azurerm_frontdoor" "main" {
  name                                         = var.frontdoorDefaultDomainPrefix
  resource_group_name                          = azurerm_resource_group.main.name
  enforce_backend_pools_certificate_name_check = false

  routing_rule {
    name               = "rule1"
    accepted_protocols = ["Https"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = ["frontend1", "frontend2"]
    forwarding_configuration {
      forwarding_protocol = "MatchRequest"
      backend_pool_name   = "backend1"
    }
  }

  backend_pool_load_balancing {
    name = "lbSettings1"
  }

  backend_pool_health_probe {
    name    = "healthProbe1"
    enabled = false
    path    = "/"
  }

  backend_pool {
    name = "backend1"
    backend {
      host_header = var.b2cBackendPool
      address     = var.b2cBackendPool
      http_port   = 80
      https_port  = 443
    }
    load_balancing_name = "lbSettings1"
    health_probe_name   = "healthProbe1"
  }

  frontend_endpoint {
    name      = "frontend1"
    host_name = format("%s.azurefd.net", var.frontdoorDefaultDomainPrefix)
  }
  frontend_endpoint {
    name      = "frontend2"
    host_name = var.frontdoorCustomDomain
  }

  tags = {
    owner = var.resourceOwner
  }
}

############################ Front Door Custom HTTPS ############################

resource "azurerm_frontdoor_custom_https_configuration" "https1" {
  frontend_endpoint_id              = azurerm_frontdoor.main.frontend_endpoints["frontend1"]
  custom_https_provisioning_enabled = false
}

resource "azurerm_frontdoor_custom_https_configuration" "https2" {
  frontend_endpoint_id              = azurerm_frontdoor.main.frontend_endpoints["frontend2"]
  custom_https_provisioning_enabled = true
  custom_https_configuration {
    certificate_source = "FrontDoor"
  }
}
