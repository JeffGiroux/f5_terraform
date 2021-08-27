# Outputs

output "mgmt_vpc" {
  description = "Management VPC name"
  value       = google_compute_network.vpc_mgmt.name
}
output "mgmt_subnet" {
  description = "Management subnet name"
  value       = google_compute_subnetwork.vpc_mgmt_sub.name
}
output "external_vpc" {
  description = "External VPC name"
  value       = google_compute_network.vpc_ext.name
}
output "external_subnet" {
  description = "External subnet name"
  value       = google_compute_subnetwork.vpc_ext_sub.name
}
output "internal_vpc" {
  description = "Internal VPC name"
  value       = google_compute_network.vpc_int.name
}
output "internal_subnet" {
  description = "Internal subnet name"
  value       = google_compute_subnetwork.vpc_int_sub.name
}
output "storage_bucket" {
  description = "Storage bucket name"
  value       = google_storage_bucket.main.name
}
