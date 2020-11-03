# Storage

# Retrieve Storage account data
data "azurerm_storage_account" "main" {
  name                = var.storage_name
  resource_group_name = var.vnet_rg
}
