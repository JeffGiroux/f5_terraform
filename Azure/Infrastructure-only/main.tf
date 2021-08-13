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

# Create the Storage Account
resource "azurerm_storage_account" "main" {
  name                     = "${var.prefix}mystorage"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment             = var.environment
    owner                   = var.owner
    group                   = var.group
    costcenter              = var.costcenter
    application             = var.application
    f5_cloud_failover_label = var.f5_cloud_failover_label
  }
}
