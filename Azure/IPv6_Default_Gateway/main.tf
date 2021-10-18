############################# Provider ###########################

terraform {
  required_version = ">= 0.14.11"
  required_providers {
    azurerm = ">= 2.81"
  }
}

# Azure Provider
provider "azurerm" {
  features {}
}

resource "random_id" "buildSuffix" {
  byte_length = 2
}

############################ Resource Group ############################

resource "azurerm_resource_group" "main" {
  name     = format("%s-rg-%s", var.projectPrefix, random_id.buildSuffix.hex)
  location = var.location
  tags = {
    owner = var.owner
  }
}
