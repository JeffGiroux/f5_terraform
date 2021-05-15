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
variable "adminSrcAddr" {
  type        = string
  description = "Allowed Admin source IP prefix"
  default     = "0.0.0.0/0"
}
variable "availabilityZones" {
  type        = list(any)
  description = "If you want the VM placed in an Azure Availability Zone, and the Azure region you are deploying to supports it, specify the numbers of the existing Availability Zone you want to use."
  default     = [1]
}

#BIG-IP info
variable "instanceCountBigIp" {
  type        = number
  description = "Number of BIG-IP instances to deploy"
  default     = 1
}


