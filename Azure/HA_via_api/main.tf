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
  subscription_id = var.sp_subscription_id
  client_id       = var.sp_client_id
  client_secret   = var.sp_client_secret
  tenant_id       = var.sp_tenant_id
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

# Create the Storage Account
resource "azurerm_storage_account" "mystorage" {
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
