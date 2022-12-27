# Main

# Google Provider
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Create a random id
resource "random_id" "buildSuffix" {
  byte_length = 2
}

# Storage Bucket
resource "google_storage_bucket" "main" {
  name          = format("%s-storage-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location      = "US"
  force_destroy = true
  labels = {
    owner                   = var.resourceOwner
    f5_cloud_failover_label = var.f5_cloud_failover_label
  }
}
