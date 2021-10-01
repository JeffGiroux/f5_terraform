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
variable "frontdoorDefaultDomainPrefix" {
  type        = string
  description = "Azure Front Door default domain prefix for subdomain 'azurefd.net' and must be unique (ex. contoso-frontend)."
  default     = null
}
variable "frontdoorCustomDomain" {
  type        = string
  description = "Custom domain to be associated with the Azure AD B2C user interface instead of the default domain (ex. login.contoso.com). You will be need to create a CNAME record in your DNS provider mapping the custom domain to the default domain (ex. login.contoso.com CNAME contoso-frontend.azurefd.net)."
  default     = null
}
variable "b2cBackendPool" {
  type        = string
  description = "The Azure AD B2C tenant name (ex. contoso.b2clogin.com)."
  default     = null
}
