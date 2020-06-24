# Outputs

output "public_vip" { value = google_compute_forwarding_rule.vip1.ip_address }
output "public_vip_url" { value = "https://${google_compute_forwarding_rule.vip1.ip_address}" }
