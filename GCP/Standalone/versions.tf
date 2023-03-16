# Set minimum Terraform version and Terraform Cloud backend
terraform {
  required_version = ">= 1.2.0"
  required_providers {
    google = ">= 4.57.0"
  }
}
