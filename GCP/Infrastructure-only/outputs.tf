# Outputs

output "mgmt_vpc" { value = google_compute_network.vpc_mgmt.name }
output "mgmt_subnet" { value = google_compute_subnetwork.vpc_mgmt_sub.name }
output "external_vpc" { value = google_compute_network.vpc_ext.name }
output "external_subnet" { value = google_compute_subnetwork.vpc_ext_sub.name }
output "internal_vpc" { value = google_compute_network.vpc_int.name }
output "internal_subnet" { value = google_compute_subnetwork.vpc_int_sub.name }
output "storage_bucket" { value = google_storage_bucket.main.name }
