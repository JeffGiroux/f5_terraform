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

# Retrieve Resource Group
data "azurerm_resource_group" "main" {
  name = var.vnet_rg
}

# Create Log Analytic Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.prefix}-law"
  sku                 = "PerNode"
  retention_in_days   = 300
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
}
