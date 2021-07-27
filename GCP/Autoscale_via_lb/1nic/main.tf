# Main

# Terraform Version Pinning
terraform {
  required_version = "~> 0.14"
  required_providers {
    google = "~> 3"
  }
}

# Google Provider
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}
