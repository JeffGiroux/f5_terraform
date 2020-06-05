output "device_mgmt_ips" {
  # Result is a map from instance id to private IP address, such as:
  #  {"i-1234" = "192.168.1.2", "i-5678" = "192.168.1.5"}
  value = {
    for instance in google_compute_instance.vm_instance :
    instance.name => "https://${instance.network_interface.1.access_config.0.nat_ip}"
  }
}

output "private_addresses" {
  description = "List of BIG-IP private addresses"
  value = {
    for instance in google_compute_instance.vm_instance :
    instance.name => "${instance.network_interface.*.network_ip}"
  }
}

output "mgmt_public_ip_01" { value = "${google_compute_instance.vm_instance.0.network_interface.1.access_config.0.nat_ip}" }

output "mgmt_public_ip_02" { value = "${var.instanceCount >= 2 ? "${google_compute_instance.vm_instance.1.network_interface.1.access_config.0.nat_ip}" : "none"}" }

output "instance01Info" { value = google_compute_instance.vm_instance.0 }

output "instance02Info" { value = "${var.instanceCount >= 2 ? "${google_compute_instance.vm_instance.1}" : "none"}" }

output "bigip_mgmt_ips" {
  value = module.bigip.device_mgmt_ips
}

# BIG-IP Password
output "password" {
  value     = random_password.password
  sensitive = true
}