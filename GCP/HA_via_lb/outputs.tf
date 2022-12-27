# Outputs

output "f5vm01_mgmt_private_ip" {
  description = "f5vm01 management private IP address"
  value       = google_compute_address.mgt.address
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
  value       = google_compute_address.ext.address
}
output "f5vm01_ext_public_ip" {
  description = "f5vm01 external public IP address (self IP)"
  value       = element(module.bigip.public_addresses[0], 0)
}
output "f5vm01_mgmt_name" {
  description = "f5vm01 management device name"
  value       = module.bigip.name
}
output "f5vm02_mgmt_private_ip" {
  description = "f5vm02 management private IP address"
  value       = google_compute_address.mgt2.address
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
  value       = google_compute_address.ext2.address
}
output "f5vm02_ext_public_ip" {
  description = "f5vm02 external public IP address (self IP)"
  value       = element(module.bigip2.public_addresses[0], 0)
}
output "f5vm02_mgmt_name" {
  description = "f5vm02 management device name"
  value       = module.bigip2.name
}
output "public_vip" {
  description = "Public IP for the BIG-IP listener (VIP)"
  value       = google_compute_forwarding_rule.vip1.ip_address
}
output "public_vip_url" {
  description = "public URL for application"
  value       = "http://${google_compute_forwarding_rule.vip1.ip_address}"
}
output "internal_vip" {
  description = "private IP address for application"
  value       = google_compute_forwarding_rule.vip2-internal.ip_address
}
output "internal_vip_url" {
  description = "private URL for application"
  value       = "http://${google_compute_forwarding_rule.vip2-internal.ip_address}"
}
