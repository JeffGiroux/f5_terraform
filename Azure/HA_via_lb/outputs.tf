# Outputs

output "sg_id" {
  description = "Security group ID"
  value       = azurerm_network_security_group.main.id
}
output "sg_name" {
  description = "Security group name"
  value       = azurerm_network_security_group.main.name
}
output "mgmt_subnet_gw" {
  description = "Default gateway of management subnet"
  value       = var.mgmt_gw
}
output "ext_subnet_gw" {
  description = "Default gateway of external subnet"
  value       = var.ext_gw
}
output "ALB_app1_pip" {
  description = "Public VIP IP for application"
  value       = azurerm_public_ip.lbpip.ip_address
}
output "f5vm01_id" {
  description = "Virual machine ID for BIG-IP 1"
  value       = azurerm_linux_virtual_machine.f5vm01.id
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
output "f5vm02_id" {
  description = "Virual machine ID for BIG-IP 2"
  value       = azurerm_linux_virtual_machine.f5vm02.id
}
output "f5vm02_mgmt_private_ip" {
  description = "Management NIC private IP address for BIG-IP 2"
  value       = azurerm_network_interface.vm02-mgmt-nic.private_ip_address
}
output "f5vm02_mgmt_public_ip" {
  description = "Management NIC public IP address for BIG-IP 2"
  value       = azurerm_public_ip.vm02mgmtpip.ip_address
}
output "f5vm02_ext_private_ip" {
  description = "External NIC private IP address for BIG-IP 2"
  value       = azurerm_network_interface.vm02-ext-nic.private_ip_address
}
