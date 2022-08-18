# Outputs

output "f5vm01_mgmt_private_ip" {
  description = "f5vm01 management private IP address"
  value       = azurerm_network_interface.vm01-mgmt-nic.private_ip_address
}
output "f5vm01_mgmt_public_ip" {
  description = "f5vm01 management public IP address"
  value       = azurerm_public_ip.vm01mgmtpip.ip_address
}
output "f5vm01_mgmt_pip_url" {
  description = "f5vm01 management public URL"
  value       = "https://${azurerm_public_ip.vm01mgmtpip.ip_address}"
}
output "f5vm01_ext_private_ip" {
  description = "f5vm01 external primary IP address (self IP)"
  value       = azurerm_network_interface.vm01-ext-nic.private_ip_address
}
output "f5vm01_ext_public_ip" {
  description = "f5vm01 external public IP address (self IP)"
  value       = azurerm_public_ip.vm01selfpip.ip_address
}
output "f5vm01_ext_secondary_ip" {
  description = "f5vm01 external secondary IP address (VIP)"
  value       = azurerm_network_interface.vm01-ext-nic.private_ip_address
}
output "f5vm01_int_private_ip" {
  description = "f5vm01 internal primary IP address"
  value       = azurerm_network_interface.vm01-int-nic.private_ip_address
}
output "f5vm02_mgmt_private_ip" {
  description = "f5vm02 management private IP address"
  value       = azurerm_network_interface.vm02-mgmt-nic.private_ip_address
}
output "f5vm02_mgmt_public_ip" {
  description = "f5vm02 management public IP address"
  value       = azurerm_public_ip.vm02mgmtpip.ip_address
}
output "f5vm02_mgmt_pip_url" {
  description = "f5vm02 management public URL"
  value       = "https://${azurerm_public_ip.vm02mgmtpip.ip_address}"
}
output "f5vm02_ext_private_ip" {
  description = "f5vm02 external primary IP address (self IP)"
  value       = azurerm_network_interface.vm02-ext-nic.private_ip_address
}
output "f5vm02_ext_public_ip" {
  description = "f5vm02 external public IP address (self IP)"
  value       = azurerm_public_ip.vm02selfpip.ip_address
}
output "f5vm02_ext_secondary_ip" {
  description = "f5vm02 external secondary IP address (VIP)"
  value       = azurerm_network_interface.vm02-ext-nic.private_ip_address
}
output "f5vm02_int_private_ip" {
  description = "f5vm01 internal primary IP address"
  value       = azurerm_network_interface.vm02-int-nic.private_ip_address
}
