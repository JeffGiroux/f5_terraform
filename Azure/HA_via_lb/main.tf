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

# Create a Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}_rg"
  location = var.location
}

# Create Log Analytic Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.prefix}-law"
  sku                 = "PerNode"
  retention_in_days   = 300
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}
