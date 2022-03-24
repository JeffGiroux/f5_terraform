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

# Create the Storage Account
resource "azurerm_storage_account" "main" {
  name                     = format("%sstorage%s", var.projectPrefix, random_id.buildSuffix.hex)
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    owner                   = var.owner
    f5_cloud_failover_label = format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)
  }
}

# Retrieve Subscription Info
data "azurerm_subscription" "main" {
}
