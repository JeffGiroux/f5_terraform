# Set minimum Terraform version and Terraform Cloud backend
terraform {
  required_version = ">= 1.2.0"
  required_providers {
    azurerm = ">= 3.48.0"
  }
}
