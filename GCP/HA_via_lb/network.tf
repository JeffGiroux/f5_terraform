# Networking

# Retrieve External Subnet data
data "google_compute_subnetwork" "vpc_ext_sub" {
  name = var.extSubnet
}
