# Outputs

output "f5vm01_ext_selfip" {
  description = "f5vm01 external self IP private address"
  value       = module.bigip.private_addresses["public_private"]["private_ip"][0]
}
output "f5vm01_ext_selfip_pip" {
  description = "f5vm01 external self IP public address"
  value       = module.bigip.public_addresses["external_primary_public"][0]
}
output "f5vm01_mgmt_ip" {
  description = "f5vm01 management private IP address"
  value       = module.bigip.private_addresses["mgmt_private"]["private_ip"][0]
}
output "f5vm01_mgmt_pip" {
  description = "f5vm01 management public IP address"
  value       = module.bigip.mgmtPublicIP
}
output "f5vm01_mgmt_pip_url" {
  description = "f5vm01 management public URL"
  value       = "https://${module.bigip.mgmtPublicIP}"
}
output "f5vm01_instance_ids" {
  description = "f5vm01 management device name"
  value       = module.bigip.bigip_instance_ids
}
output "public_vip" {
  description = "public IP address for application"
  value       = module.bigip.public_addresses["external_secondary_public"][0]
}
output "public_vip_url" {
  description = "public URL for application"
  value       = "http://${module.bigip.public_addresses["external_secondary_public"][0]}"
}




# output "public_vip_pip" {
#   description = "Public IP for the BIG-IP listener (VIP)"
#   value       = aws_eip.vip-pip.public_ip
# }
# output "f5vm01_mgmt_private_ip" {
#   description = "f5vm01 management private IP address"
#   value       = aws_network_interface.vm01-mgmt-nic.private_ip
# }
# output "f5vm01_mgmt_public_ip" {
#   description = "f5vm01 management public IP address"
#   value       = aws_eip.vm01-mgmt-pip.public_ip
# }
# output "f5vm01_ext_private_ip" {
#   description = "f5vm01 external primary IP address (self IP)"
#   value       = aws_network_interface.vm01-ext-nic.private_ip
# }
# output "f5vm01_ext_secondary_ip" {
#   description = "f5vm01 external secondary IP address (VIP)"
#   value       = local.vm01_vip_ips.app1.ip
# }
# output "f5vm01_int_private_ip" {
#   description = "f5vm01 internal primary IP address"
#   value       = aws_network_interface.vm01-int-nic.private_ip
# }
