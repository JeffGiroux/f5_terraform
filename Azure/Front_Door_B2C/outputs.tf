# Outputs

output "resource_group" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}
output "front_door" {
  description = "Front Door Host Name"
  value       = azurerm_frontdoor.main.cname
}
