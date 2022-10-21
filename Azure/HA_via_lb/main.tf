# Main

# Azure Provider
provider "azurerm" {
  features {}
}

# Create a random id
resource "random_id" "buildSuffix" {
  byte_length = 2
}

# Create a Resource Group for BIG-IP
resource "azurerm_resource_group" "main" {
  name     = format("%s-rg-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location = var.location
  tags = {
    owner = var.resourceOwner
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
    owner = var.resourceOwner
  }
}

# Retrieve Subscription Info
data "azurerm_subscription" "main" {
}
data "azurerm_client_config" "current" {
}
data "azurerm_key_vault" "main" {
  count = var.az_keyvault_authentication == true ? 1 : 0
  name                = var.keyvault_name
  resource_group_name = var.keyvault_rg
}
data "azurerm_user_assigned_identity" "main" {
  count = var.az_keyvault_authentication == true ? 1 : 0
  name                = var.user_identity
  resource_group_name = var.keyvault_rg
}


resource "azurerm_key_vault_access_policy" "main" {
  count = var.az_keyvault_authentication == true ? 1 : 0
  key_vault_id = data.azurerm_key_vault.main[0].id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_user_assigned_identity.main[0].principal_id

  secret_permissions = [
    "Get",
  ]
}