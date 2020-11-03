# Outputs

output "vnet" { value = azurerm_virtual_network.main.name }
output "mgmt_subnet" { value = azurerm_subnet.mgmt.address_prefix }
output "external_subnet" { value = azurerm_subnet.external.address_prefix }
output "internal_subnet" { value = azurerm_subnet.internal.address_prefix }
output "storage_bucket" { value = azurerm_storage_account.mystorage.name }
