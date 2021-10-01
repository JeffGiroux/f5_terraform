resource "random_id" "buildSuffix" {
  byte_length = 2
}
variable "projectPrefix" {
  type        = string
  description = "prefix for resources"
  default     = "demo"
}
variable "resourceOwner" {
  type        = string
  description = "name of the person or customer running the solution"
}
variable "azureLocation" {
  type        = string
  description = "location where Azure resources are deployed (abbreviated Azure Region name)"
}
variable "ssh_key" {
  type        = string
  description = "public key used for authentication in ssh-rsa format"
}
variable "adminSrcAddr" {
  type        = string
  description = "Allowed Admin source IP prefix"
  default     = "0.0.0.0/0"
}
