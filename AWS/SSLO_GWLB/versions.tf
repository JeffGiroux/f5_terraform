# Set minimum Terraform version and Terraform Cloud backend
terraform {
  required_version = ">= 1.2.0"
  required_providers {
    aws = ">= 4.59.0"
  }
}
