# Outputs

output "public_vip" {
  description = "public IP address for application"
  value       = google_compute_forwarding_rule.vip1.ip_address
}
output "public_vip_url" {
  description = "public URL for application"
  value       = "http://${google_compute_forwarding_rule.vip1.ip_address}"
}
