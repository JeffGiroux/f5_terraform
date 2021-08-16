# Outputs

output "bigip_resource_group" { value = azurerm_resource_group.main.name }
output "storage_bucket" { value = azurerm_storage_account.main.name }
output "Public_VIP_pip" { value = azurerm_public_ip.pubvippip.ip_address }

output "f5vm01_mgmt_private_ip" { value = azurerm_network_interface.vm01-mgmt-nic.private_ip_address }
output "f5vm01_mgmt_public_ip" { value = azurerm_public_ip.vm01mgmtpip.ip_address }
output "f5vm01_ext_private_ip" { value = azurerm_network_interface.vm01-ext-nic.private_ip_address }
output "f5vm01_int_private_ip" { value = azurerm_network_interface.vm01-int-nic.private_ip_address }

output "f5vm02_mgmt_private_ip" { value = azurerm_network_interface.vm02-mgmt-nic.private_ip_address }
output "f5vm02_mgmt_public_ip" { value = azurerm_public_ip.vm02mgmtpip.ip_address }
output "f5vm02_ext_private_ip" { value = azurerm_network_interface.vm02-ext-nic.private_ip_address }
output "f5vm02_int_private_ip" { value = azurerm_network_interface.vm02-int-nic.private_ip_address }
