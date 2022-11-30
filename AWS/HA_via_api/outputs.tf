# Outputs

output "route_table" {
  description = "Route table ID"
  value       = aws_route_table.main.id
}
output "storage_bucket" {
  description = "AWS storage bucket ARN"
  value       = aws_s3_bucket.main.arn
}
output "f5vm01_mgmt_private_ip" {
  description = "f5vm01 management private IP address"
  value       = module.bigip.private_addresses["mgmt_private"]["private_ip"][0]
}
output "f5vm01_mgmt_public_ip" {
  description = "f5vm01 management public IP address"
  value       = module.bigip.mgmtPublicIP
}
output "f5vm01_mgmt_pip_url" {
  description = "f5vm01 management public URL"
  value       = "https://${module.bigip.mgmtPublicIP}"
}
output "f5vm01_ext_private_ip" {
  description = "f5vm01 external primary IP address (self IP)"
  value       = module.bigip.private_addresses["public_private"]["private_ip"][0]
}
output "f5vm01_ext_public_ip" {
  description = "f5vm01 external public IP address (self IP)"
  value       = module.bigip.public_addresses["external_primary_public"][0]
}
output "f5vm01_ext_secondary_ip" {
  description = "f5vm01 external secondary IP address (VIP)"
  value       = local.vm01_vip_ips.app1.ip
}
output "f5vm01_int_private_ip" {
  description = "f5vm01 internal primary IP address"
  value       = module.bigip.private_addresses["internal_private"]["private_ip"][0]
}
output "f5vm01_instance_ids" {
  description = "f5vm01 management device name"
  value       = module.bigip.bigip_instance_ids
}
output "f5vm02_mgmt_private_ip" {
  description = "f5vm02 management private IP address"
  value       = module.bigip2.private_addresses["mgmt_private"]["private_ip"][0]
}
output "f5vm02_mgmt_public_ip" {
  description = "f5vm02 management public IP address"
  value       = module.bigip2.mgmtPublicIP
}
output "f5vm02_mgmt_pip_url" {
  description = "f5vm02 management public URL"
  value       = "https://${module.bigip2.mgmtPublicIP}"
}
output "f5vm02_ext_private_ip" {
  description = "f5vm02 external primary IP address (self IP)"
  value       = module.bigip2.private_addresses["public_private"]["private_ip"][0]
}
output "f5vm02_ext_public_ip" {
  description = "f5vm02 external public IP address (self IP)"
  value       = module.bigip2.public_addresses["external_primary_public"][0]
}
output "f5vm02_ext_secondary_ip" {
  description = "f5vm02 external secondary IP address (VIP)"
  value       = local.vm02_vip_ips.app1.ip
}
output "f5vm02_int_private_ip" {
  description = "f5vm01 internal primary IP address"
  value       = module.bigip2.private_addresses["internal_private"]["private_ip"][0]
}
output "f5vm02_instance_ids" {
  description = "f5vm02 management device name"
  value       = module.bigip2.bigip_instance_ids
}
output "public_vip" {
  description = "Public IP for the BIG-IP listener (VIP)"
  value       = module.bigip2.public_addresses["external_secondary_public"][0]
}
output "public_vip_url" {
  description = "public URL for application"
  value       = "http://${module.bigip2.public_addresses["external_secondary_public"][0]}"
}
