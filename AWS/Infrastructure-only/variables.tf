# Variables

variable "awsRegion" {
  description = "aws region"
  type        = string
  default     = "us-west-2"
}
variable "projectPrefix" {
  type        = string
  description = "prefix for resources"
  default     = "myDemo"
}
variable "resourceOwner" {
  type        = string
  description = "owner of the deployment, for tagging purposes"
  default     = "myName"
}
