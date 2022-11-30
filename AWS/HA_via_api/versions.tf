# Set minimum Terraform version and Terraform Cloud backend
terraform {
  required_version = "~> 1.0"
  required_providers {
    aws = "~> 4.0"
  }
}
