# Main

# Terraform Version Pinning
terraform {
  required_version = ">= 0.14.5"
  required_providers {
    azurerm = ">= 3"
  }
}

# Azure Provider
provider "azurerm" {
  features {}
}

# Create a Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.projectPrefix}_rg"
  location = var.location
  tags = {
    owner = var.owner
  }
}
