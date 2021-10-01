# Main

# Terraform Version Pinning
terraform {
  required_version = "~> 0.14"
  required_providers {
    azurerm = "~> 2"
  }
}

# Azure Provider
provider "azurerm" {
  features {}
}

# Create a Resource Group
resource "azurerm_resource_group" "main" {
  name     = format("%s-rg-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location = var.azureLocation
  tags = {
    owner = var.resourceOwner
  }
}

# Retrieve Subscription Info
data "azurerm_subscription" "main" {
}
