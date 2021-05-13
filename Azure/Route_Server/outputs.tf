output "vnetIdHub" {
  description = "Hub VNet ID"
  value       = module.network["hub"].vnet_id
}
output "vnetIdSpoke1" {
  description = "Spoke1 VNet ID"
  value       = module.network["spoke1"].vnet_id
}
output "vnetIdSpoke2" {
  description = "Spoke2 VNet ID"
  value       = module.network["spoke2"].vnet_id
}
