# Outputs

output "resource_group" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}
output "vnet" {
  description = "VNet name"
  value       = azurerm_virtual_network.main.name
}
output "mgmt_subnet" {
  description = "Management subnet address prefix"
  value       = azurerm_subnet.mgmt.address_prefixes
}
output "external_subnet" {
  description = "External subnet address prefix"
  value       = azurerm_subnet.external.address_prefixes
}
output "internal_subnet" {
  description = "Internal subnet address prefix"
  value       = azurerm_subnet.internal.address_prefixes
}
