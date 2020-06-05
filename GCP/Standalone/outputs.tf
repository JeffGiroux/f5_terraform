# Outputs

output "private_addresses" { value = google_compute_instance.f5vm01.network_interface.*.network_ip }
output "mgmt_public_ip_01" { value = google_compute_instance.f5vm01.network_interface.1.access_config.0.nat_ip }
