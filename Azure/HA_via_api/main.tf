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

# Create a Resource Group for BIG-IP
resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}_bigip_rg"
  location = var.location
  tags = {
    owner = var.owner
  }
}

# Create Log Analytic Workspace
resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.prefix}-law"
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
  name                     = "${var.prefix}mystorage"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    owner                   = var.owner
    f5_cloud_failover_label = var.f5_cloud_failover_label
  }
}

# Retrieve Subscription Info
data "azurerm_subscription" "main" {
}
