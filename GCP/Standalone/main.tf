# Main

# Terraform Version Pinning
terraform {
    required_version = "~> 0.12.26"
    required_providers {
        google = "~> 3.24.0"
    }
}

# Google Provider
provider "google" {
  project = var.GCP_PROJECT_ID
  region  = var.GCP_REGION
  zone    = var.GCP_ZONE
}

# Create Random Suffix
resource "random_pet" "buildSuffix" {
  keepers = {
    # Generate a new pet name each time we switch to a new AMI id
    #ami_id = var.ami_id}"
    prefix = var.projectPrefix
  }
  #length = ""
  #prefix = var.projectPrefix}"
  separator = "-"
}

