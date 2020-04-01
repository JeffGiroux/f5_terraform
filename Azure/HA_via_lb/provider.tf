# Configure the Microsoft Azure Provider, replace Service Principal and Subscription with your own
provider "azurerm" {
    subscription_id = "${var.SP["subscription_id"]}"
    client_id       = "${var.SP["client_id"]}"
    client_secret   = "${var.SP["client_secret"]}"
    tenant_id       = "${var.SP["tenant_id"]}"
}

