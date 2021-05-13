#Project info
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

#Azure info
variable "azureLocation" {
  type        = string
  description = "location where Azure resources are deployed (abbreviated Azure Region name)"
}
variable "keyName" {
  type        = string
  description = "instance key pair name"
}

