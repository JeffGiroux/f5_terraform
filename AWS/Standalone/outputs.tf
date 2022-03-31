# Outputs

output "public_vip_pip" {
  description = "Public IP for the BIG-IP listener (VIP)"
  value       = aws_eip.vip-pip.public_ip
}
output "f5vm01_mgmt_private_ip" {
  description = "f5vm01 management private IP address"
  value       = aws_network_interface.vm01-mgmt-nic.private_ip
}
output "f5vm01_mgmt_public_ip" {
  description = "f5vm01 management public IP address"
  value       = aws_eip.vm01-mgmt-pip.public_ip
}
output "f5vm01_ext_private_ip" {
  description = "f5vm01 external primary IP address (self IP)"
  value       = aws_network_interface.vm01-ext-nic.private_ip
}
output "f5vm01_ext_secondary_ip" {
  description = "f5vm01 external secondary IP address (VIP)"
  value       = local.vm01_vip_ips.app1.ip
}
output "f5vm01_int_private_ip" {
  description = "f5vm01 internal primary IP address"
  value       = aws_network_interface.vm01-int-nic.private_ip
}
