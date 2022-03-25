# Outputs

output "Public_VIP_pip" {
  description = "Public VIP IP for application"
  value       = azurerm_public_ip.pubvippip.ip_address
}
output "f5vm01_mgmt_private_ip" {
  description = "Management NIC private IP address for BIG-IP 1"
  value       = azurerm_network_interface.vm01-mgmt-nic.private_ip_address
}
output "f5vm01_mgmt_public_ip" {
  description = "Management NIC public IP address for BIG-IP 1"
  value       = azurerm_public_ip.vm01mgmtpip.ip_address
}
output "f5vm01_ext_private_ip" {
  description = "External NIC private IP address for BIG-IP 1"
  value       = azurerm_network_interface.vm01-ext-nic.private_ip_address
}
output "f5vm01_int_private_ip" {
  description = "Internal NIC private IP address for BIG-IP 1"
  value       = azurerm_network_interface.vm01-int-nic.private_ip_address
}
