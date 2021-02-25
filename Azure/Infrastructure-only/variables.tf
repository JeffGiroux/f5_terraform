# Variables

# Azure Environment
variable "sp_subscription_id" {}
variable "sp_client_id" {}
variable "sp_client_secret" {}
variable "sp_tenant_id" {}
variable "prefix" { default = "mydemo123" }
variable "location" { default = "westus2" }
variable "adminSrcAddr" { default = "0.0.0.0/0" }


# NETWORK
variable "vnet_cidr" { default = "10.90.0.0/16" }
variable "mgmt_address_prefix" { default = "10.90.1.0/24" }
variable "ext_address_prefix" { default = "10.90.2.0/24" }
variable "int_address_prefix" { default = "10.90.3.0/24" }

# Tags
variable "purpose" { default = "public" }
variable "environment" { default = "f5env" } #ex. dev/staging/prod
variable "owner" { default = "f5owner" }
variable "group" { default = "f5group" }
variable "costcenter" { default = "f5costcenter" }
variable "application" { default = "f5app" }
variable "f5_cloud_failover_label" { default = "mydeployment" } #Cloud Failover Tag
