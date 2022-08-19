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
output "public_vip" {
  description = "Public IP for the BIG-IP listener (VIP)"
  value       = google_compute_forwarding_rule.vip1.ip_address
}
output "public_vip_url" {
  description = "public URL for application"
  value       = "http://${google_compute_forwarding_rule.vip1.ip_address}"
}
