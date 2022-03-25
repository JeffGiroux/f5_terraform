# Main

# Terraform Version Pinning
terraform {
  required_version = ">= 0.14.5"
  required_providers {
    azurerm = ">= 3"
  }
}

# Azure Provider
provider "azurerm" {
  features {}
}

resource "random_id" "buildSuffix" {
  byte_length = 2
}

# Create a Resource Group for BIG-IP
resource "azurerm_resource_group" "main" {
  name     = format("%s-rg-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location = var.location
  tags = {
    owner = var.owner
  }
}

# Create Log Analytic Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = format("%s-law-%s", var.projectPrefix, random_id.buildSuffix.hex)
  sku                 = "PerNode"
  retention_in_days   = 300
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags = {
    owner = var.owner
  }
}

# Retrieve Subscription Info
data "azurerm_subscription" "main" {
}
