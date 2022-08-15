# Set minimum Terraform version and Terraform Cloud backend
terraform {
  required_version = ">= 0.14.5"
  required_providers {
    google = ">= 4"
  }
}
