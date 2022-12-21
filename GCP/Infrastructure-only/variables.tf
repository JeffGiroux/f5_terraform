# Variables

variable "projectPrefix" {
  type        = string
  default     = "demo"
  description = "This value is inserted at the beginning of each Google object (alpha-numeric, no special character)"
}
variable "gcp_project_id" {
  type        = string
  default     = null
  description = "GCP Project ID for provider"
}
variable "gcp_region" {
  type        = string
  default     = "us-west1"
  description = "GCP Region for provider"
}
variable "gcp_zone_1" {
  type        = string
  default     = "us-west1-a"
  description = "GCP Zone 1 for provider"
}
variable "adminSrcAddr" {
  type        = string
  description = "Allowed Admin source IP prefix"
  default     = "0.0.0.0/0"
}
variable "mgmt_address_prefix" {
  type        = string
  default     = "10.1.1.0/24"
  description = "Management subnet address prefix"
}
variable "ext_address_prefix" {
  type        = string
  default     = "10.1.10.0/24"
  description = "External subnet address prefix"
}
variable "int_address_prefix" {
  type        = string
  default     = "10.1.20.0/24"
  description = "Internal subnet address prefix"
}
variable "resourceOwner" {
  type        = string
  default     = null
  description = "This is a tag used for object creation. Example is last name."
}
variable "f5_cloud_failover_label" {
  type        = string
  default     = "myFailover"
  description = "This is a tag used for F5 Cloud Failover Extension to identity which cloud objects to move during a failover event."
}
