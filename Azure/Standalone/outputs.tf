# Outputs

output "Public_VIP_pip" {
  description = "Public VIP IP for application"
  value       = azurerm_public_ip.pubvippip.ip_address
}
output "f5vm01_mgmt_private_ip" {
  description = "f5vm01 management private IP address"
  value       = azurerm_network_interface.vm01-mgmt-nic.private_ip_address
}
output "f5vm01_mgmt_public_ip" {
  description = "f5vm01 management public IP address"
  value       = azurerm_public_ip.vm01mgmtpip.ip_address
}
output "f5vm01_ext_private_ip" {
  description = "f5vm01 external primary IP address (self IP)"
  value       = azurerm_network_interface.vm01-ext-nic.private_ip_address
}
output "f5vm01_int_private_ip" {
  description = "f5vm01 internal primary IP address"
  value       = azurerm_network_interface.vm01-int-nic.private_ip_address
}
