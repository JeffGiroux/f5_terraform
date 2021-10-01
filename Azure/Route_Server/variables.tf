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
variable "instanceCountBigIp" {
  type        = number
  description = "Number of BIG-IP instances to deploy"
  default     = 1
}
variable "f5UserName" {
  description = "The admin username of the F5 BIG-IP that will be deployed"
  default     = "azureuser"
}
variable "f5Version" {
  description = "The BIG-IP version"
  default     = "15.1.201000"
}
