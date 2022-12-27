# Outputs

output "mgmt_vpc" {
  description = "Management VPC name"
  value       = google_compute_network.vpc_mgmt.name
}
output "mgmt_subnet_name" {
  description = "Management subnet name"
  value       = google_compute_subnetwork.vpc_mgmt_sub.name
}
output "external_vpc" {
  description = "External VPC name"
  value       = google_compute_network.vpc_ext.name
}
output "external_subnet_name" {
  description = "External subnet name"
  value       = google_compute_subnetwork.vpc_ext_sub.name
}
output "internal_vpc" {
  description = "Internal VPC name"
  value       = google_compute_network.vpc_int.name
}
output "internal_subnet_name" {
  description = "Internal subnet name"
  value       = google_compute_subnetwork.vpc_int_sub.name
}
