# Configure the Microsoft Azure Provider, replace Service Principal and Subscription with your own
provider "azurerm" {
    subscription_id = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    client_id       = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    client_secret   = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    tenant_id       = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
}

