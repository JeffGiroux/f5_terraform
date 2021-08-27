# Outputs

output "f5vm01_ext_selfip" {
  description = "f5vm01 external self IP private address"
  value       = google_compute_instance.f5vm01.network_interface.0.network_ip
}
output "f5vm01_ext_selfip_pip" {
  description = "f5vm01 external self IP public address"
  value       = google_compute_instance.f5vm01.network_interface.0.access_config.0.nat_ip
}
output "f5vm01_mgmt_ip" {
  description = "f5vm01 management private IP address"
  value       = google_compute_instance.f5vm01.network_interface.1.network_ip
}
output "f5vm01_mgmt_pip" {
  description = "f5vm01 management public IP address"
  value       = google_compute_instance.f5vm01.network_interface.1.access_config.0.nat_ip
}
output "f5vm01_mgmt_pip_url" {
  description = "f5vm01 management public URL"
  value       = "https://${google_compute_instance.f5vm01.network_interface.1.access_config.0.nat_ip}"
}
output "f5vm01_mgmt_name" {
  description = "f5vm01 management device name"
  value       = google_compute_instance.f5vm01.name
}
output "f5vm02_ext_selfip" {
  description = "f5vm02 external self IP private address"
  value       = google_compute_instance.f5vm02.network_interface.0.network_ip
}
output "f5vm02_ext_selfip_pip" {
  description = "f5vm02 external self IP public address"
  value       = google_compute_instance.f5vm02.network_interface.0.access_config.0.nat_ip
}
output "f5vm02_mgmt_ip" {
  description = "f5vm02 management private IP address"
  value       = google_compute_instance.f5vm02.network_interface.1.network_ip
}
output "f5vm02_mgmt_pip" {
  description = "f5vm02 management public IP address"
  value       = google_compute_instance.f5vm02.network_interface.1.access_config.0.nat_ip
}
output "f5vm02_mgmt_pip_url" {
  description = "f5vm02 management public URL"
  value       = "https://${google_compute_instance.f5vm02.network_interface.1.access_config.0.nat_ip}"
}
output "f5vm02_mgmt_name" {
  description = "f5vm02 management device name"
  value       = google_compute_instance.f5vm02.name
}
output "public_vip" {
  description = "public IP address for application"
  value       = google_compute_forwarding_rule.vip1.ip_address
}
output "public_vip_url" {
  description = "public URL for application"
  value       = "https://${google_compute_forwarding_rule.vip1.ip_address}"
}
