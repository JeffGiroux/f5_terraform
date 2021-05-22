# Set minimum Terraform version and Terraform Cloud backend
terraform {
  required_version = "~> 0.14"
  required_providers {
    azurerm = "~> 2"
  }
}