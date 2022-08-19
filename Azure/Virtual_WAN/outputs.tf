# Outputs

output "vnetIdNva" {
  description = "NVA VNet ID"
  value       = module.network["nva"].vnet_id
}
output "vnetIdSpoke1" {
  description = "Spoke1 VNet ID"
  value       = module.network["spoke1"].vnet_id
}
output "vnetIdSpoke2" {
  description = "Spoke2 VNet ID"
  value       = module.network["spoke2"].vnet_id
}
output "bigipPublicIP" {
  description = "The public ip address allocated for the BIG-IP"
  value       = module.bigip.*.mgmtPublicIP
}
output "bigipUserName" {
  description = "The user name for the BIG-IP"
  value       = module.bigip.*.f5_username
}
output "bigipPassword" {
  description = "The password for the BIG-IP (if dynamic_password is choosen it will be random generated password or if azure_keyvault is choosen it will be key vault secret name )"
  value       = module.bigip.*.bigip_password
}
output "clientPublicIP" {
  description = "The public ip address allocated for the client/jumphost in Spoke 1"
  value       = module.client.public_ip_address
}
output "clientPrivateIP" {
  description = "The private ip address allocated for the client/jumphost in Spoke 1"
  value       = module.client.network_interface_private_ip
}
output "appPublicIP" {
  description = "The public ip address allocated for the app in Spoke 2"
  value       = module.app.public_ip_address
}
output "appPrivateIP" {
  description = "The private ip address allocated for the webapp in Spoke 2"
  value       = module.app.network_interface_private_ip
}
output "bigip-private-ips" {
  description = "The private ip address for BIG-IP"
  value       = module.bigip.*.private_addresses
}
