# Configure the Microsoft Azure Provider, replace Service Principal and Subscription with your own.
# Place these values in terraform.tfvars.

provider "azurerm" {
  version         = "=2.1.0"
  features {}
  subscription_id = "${var.sp_subscription_id}"
  client_id       = "${var.sp_client_id}"
  client_secret   = "${var.sp_client_secret}"
  tenant_id       = "${var.sp_tenant_id}"
}

