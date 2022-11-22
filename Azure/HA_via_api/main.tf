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
resource "azurerm_log_analytics_workspace" "main" {
  name                = format("%s-law-%s", var.projectPrefix, random_id.buildSuffix.hex)
  sku                 = "PerNode"
  retention_in_days   = 300
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags = {
    owner = var.resourceOwner
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
    owner                   = var.resourceOwner
    f5_cloud_failover_label = var.f5_cloud_failover_label
  }
}

# Subscription Info
data "azurerm_subscription" "main" {
}

# Note: Jeff Giroux (REMOVE LATER)
#       https://github.com/F5Networks/terraform-azure-bigip-module/issues/42
#       The user_identity is not passed in BIG-IP module to the
#       Key Vault policy. As a result, the Terraform auto created
#       user identity is assigned the policy instead of the
#       user-supplied managed identity.

# Managed Identity Info
data "azurerm_user_assigned_identity" "main" {
  count               = var.az_keyvault_authentication ? 1 : 0
  name                = split("/", var.user_identity)[8]
  resource_group_name = split("/", var.user_identity)[4]
}

# Key Vault info
data "azurerm_key_vault" "main" {
  count               = var.az_keyvault_authentication ? 1 : 0
  name                = var.keyvault_name
  resource_group_name = var.keyvault_rg
}

# Create Key Vault policies
resource "azurerm_key_vault_access_policy" "main" {
  count        = var.az_keyvault_authentication ? 1 : 0
  key_vault_id = data.azurerm_key_vault.main[0].id
  tenant_id    = data.azurerm_subscription.main.tenant_id
  object_id    = data.azurerm_user_assigned_identity.main[0].principal_id

  key_permissions = [
    "Get", "List", "Update", "Create", "Import", "Delete", "Recover", "Backup", "Restore",
  ]
  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Restore", "Backup", "Purge",
  ]
}
