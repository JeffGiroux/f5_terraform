# Outputs

output "private_addresses" {
  description = "List of BIG-IP private addresses"
  value = {
    for instance in google_compute_instance.vm_instance :
    instance.name => "${instance.network_interface.*.network_ip}"
  }
}

output "mgmt_public_ip_01" { value = "${google_compute_instance.vm_instance.0.network_interface.1.access_config.0.nat_ip}" }
#output "mgmt_public_ip_02" { value = "${var.instanceCount >= 2 ? "${google_compute_instance.vm_instance.1.network_interface.1.access_config.0.nat_ip}" : "none"}" }
#output "instance01Info" { value = google_compute_instance.vm_instance.0 }
#output "instance02Info" { value = "${var.instanceCount >= 2 ? "${google_compute_instance.vm_instance.1}" : "none"}" }

