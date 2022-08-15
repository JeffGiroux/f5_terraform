# Main

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
