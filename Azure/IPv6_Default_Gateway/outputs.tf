# Outputs

output "resource_group" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}
output "backend_private_ip" {
  description = "Private IP address (v4 and v6) for backend"
  value       = azurerm_network_interface.backend.private_ip_addresses
}
output "bigip_mgmt_private_ip" {
  description = "Management NIC private IP address for BIG-IP 1"
  value       = azurerm_network_interface.bigipMgmtNic.private_ip_address
}
output "bigip_mgmt_public_ip" {
  description = "Management NIC public IP address for BIG-IP 1"
  value       = azurerm_public_ip.bigipMgmtPip.ip_address
}
output "bigip_ext_private_ip" {
  description = "External NIC private IPv4 address (v4 and v6) for BIG-IP 1"
  value       = azurerm_network_interface.bigipExtNic.private_ip_addresses
}
output "bigip_ext_public_ip" {
  description = "External NIC public IPv4 address for BIG-IP 1"
  value       = azurerm_public_ip.bigipSelfPip.ip_address
}
output "bigip_VIP_public_ip" {
  description = "Public VIP IPv4 for application"
  value       = azurerm_public_ip.bigipVipPip.ip_address
}
output "bigip_ext_public_ipv6" {
  description = "External NIC public IPv6 address for BIG-IP 1"
  value       = azurerm_public_ip.bigipSelfPipV6.ip_address
}
output "bigip_int_private_ip" {
  description = "Internal NIC private IP address (v4 and v6) for BIG-IP 1"
  value       = azurerm_network_interface.bigipIntNic.private_ip_addresses
}
