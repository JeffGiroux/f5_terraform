# Variables

variable "projectPrefix" {
  type        = string
  default     = "demo"
  description = "This value is inserted at the beginning of each Azure object (alpha-numeric, no special character)"
}
variable "location" {
  type        = string
  default     = "westus2"
  description = "Azure Location of the deployment"
}
variable "adminSrcAddr" {
  type        = string
  description = "Allowed Admin source IP prefix"
  default     = "0.0.0.0/0"
}
variable "vnet_cidr" {
  type        = string
  default     = "10.90.0.0/16"
  description = "CIDR IP Address range of the Virtual Network"
}
variable "mgmt_address_prefix" {
  type        = string
  default     = "10.90.1.0/24"
  description = "Management subnet address prefix"
}
variable "ext_address_prefix" {
  type        = string
  default     = "10.90.2.0/24"
  description = "External subnet address prefix"
}
variable "int_address_prefix" {
  type        = string
  default     = "10.90.3.0/24"
  description = "Internal subnet address prefix"
}
variable "resourceOwner" {
  type        = string
  default     = null
  description = "This is a tag used for object creation. Example is last name."
}
variable "f5_cloud_failover_label" {
  type        = string
  default     = "mydeployment"
  description = "This is a tag used for F5 Cloud Failover Extension to identity which cloud objects to move during a failover event."
}
