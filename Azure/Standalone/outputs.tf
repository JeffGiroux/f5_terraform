# Outputs

output "mgmt_subnet_gw" { value = var.mgmt_gw }
output "ext_subnet_gw" { value = var.ext_gw }
output "Public_VIP_pip" { value = azurerm_public_ip.pubvippip.ip_address }

output "f5vm01_id" { value = azurerm_linux_virtual_machine.f5vm01.id }
output "f5vm01_mgmt_private_ip" { value = azurerm_network_interface.vm01-mgmt-nic.private_ip_address }
output "f5vm01_mgmt_public_ip" { value = azurerm_public_ip.vm01mgmtpip.ip_address }
output "f5vm01_ext_private_ip" { value = azurerm_network_interface.vm01-ext-nic.private_ip_address }
