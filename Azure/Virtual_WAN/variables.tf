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
variable "availability_zone" {
  type        = number
  description = "Azure Availability Zone for BIG-IP 1"
  default     = 1
}
variable "instanceCountBigIp" {
  type        = number
  description = "Number of BIG-IP instances to deploy"
  default     = 1
}
variable "instance_type" {
  type        = string
  default     = "Standard_DS4_v2"
  description = "Azure instance type to be used for the BIG-IP VE"
}
variable "image_name" {
  type        = string
  default     = "f5-big-best-plus-hourly-25mbps"
  description = "F5 SKU (image) to deploy. Note: The disk size of the VM will be determined based on the option you select.  **Important**: If intending to provision multiple modules, ensure the appropriate value is selected, such as ****AllTwoBootLocations or AllOneBootLocation****."
}
variable "product" {
  type        = string
  default     = "f5-big-ip-best"
  description = "Azure BIG-IP VE Offer"
}
variable "bigip_version" {
  type        = string
  default     = "16.1.303000"
  description = "BIG-IP Version"
}
variable "f5_username" {
  type        = string
  default     = "azureuser"
  description = "User name for the BIG-IP"
}
variable "f5_password" {
  type        = string
  default     = "Default12345!"
  description = "BIG-IP Password or Key Vault secret name (value should be Key Vault secret name when az_key_vault_authentication = true, ex. my-bigip-secret)"
}
variable "az_keyvault_authentication" {
  type        = bool
  default     = false
  description = "Whether to use key vault to pass authentication"
}
variable "keyvault_rg" {
  type        = string
  default     = ""
  description = "The name of the resource group in which the Azure Key Vault exists"
}
variable "keyvault_name" {
  type        = string
  default     = null
  description = "Name of Key Vault"
}
variable "keyvault_secret" {
  type        = string
  default     = null
  description = "Name of Key Vault secret with BIG-IP password"
}
variable "user_identity" {
  type        = string
  default     = null
  description = "The ID of the managed user identity to assign to the BIG-IP instance"
}
variable "ssh_key" {
  type        = string
  description = "public key used for authentication in /path/file format (e.g. /.ssh/id_rsa.pub)"
}
variable "dns_server" {
  type        = string
  default     = "8.8.8.8"
  description = "Leave the default DNS server the BIG-IP uses, or replace the default DNS server with the one you want to use"
}
variable "dns_suffix" {
  type        = string
  default     = "example.com"
  description = "DNS suffix for your domain in the GCP project"
}
variable "ntp_server" {
  type        = string
  default     = "0.us.pool.ntp.org"
  description = "Leave the default NTP server the BIG-IP uses, or replace the default NTP server with the one you want to use"
}
variable "timezone" {
  type        = string
  default     = "UTC"
  description = "If you would like to change the time zone the BIG-IP uses, enter the time zone you want to use. This is based on the tz database found in /usr/share/zoneinfo (see the full list [here](https://github.com/F5Networks/f5-azure-arm-templates/blob/master/azure-timezone-list.md)). Example values: UTC, US/Pacific, US/Eastern, Europe/London or Asia/Singapore."
}
variable "DO_URL" {
  type        = string
  default     = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.36.1/f5-declarative-onboarding-1.36.1-1.noarch.rpm"
  description = "URL to download the BIG-IP Declarative Onboarding module"
}
variable "AS3_URL" {
  type        = string
  default     = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.43.0/f5-appsvcs-3.43.0-2.noarch.rpm"
  description = "URL to download the BIG-IP Application Service Extension 3 (AS3) module"
}
variable "TS_URL" {
  type        = string
  default     = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.32.0/f5-telemetry-1.32.0-2.noarch.rpm"
  description = "URL to download the BIG-IP Telemetry Streaming module"
}
variable "FAST_URL" {
  type        = string
  default     = "https://github.com/F5Networks/f5-appsvcs-templates/releases/download/v1.24.0/f5-appsvcs-templates-1.24.0-1.noarch.rpm"
  description = "URL to download the BIG-IP FAST module"
}
variable "INIT_URL" {
  type        = string
  default     = "https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.6.0/dist/f5-bigip-runtime-init-1.6.0-1.gz.run"
  description = "URL to download the BIG-IP runtime init"
}
variable "libs_dir" {
  type        = string
  default     = "/config/cloud/azure/node_modules"
  description = "Directory on the BIG-IP to download the A&O Toolchain into"
}
variable "bigIqHost" {
  type        = string
  default     = ""
  description = "This is the BIG-IQ License Manager host name or IP address"
}
variable "bigIqUsername" {
  type        = string
  default     = "azureuser"
  description = "Admin name for BIG-IQ"
}
variable "bigIqPassword" {
  type        = string
  default     = "Default12345!"
  description = "Admin Password for BIG-IQ"
}
variable "bigIqLicenseType" {
  type        = string
  default     = "licensePool"
  description = "BIG-IQ license type"
}
variable "bigIqLicensePool" {
  type        = string
  default     = ""
  description = "BIG-IQ license pool name"
}
variable "bigIqSkuKeyword1" {
  type        = string
  default     = "key1"
  description = "BIG-IQ license SKU keyword 1"
}
variable "bigIqSkuKeyword2" {
  type        = string
  default     = "key2"
  description = "BIG-IQ license SKU keyword 2"
}
variable "bigIqUnitOfMeasure" {
  type        = string
  default     = "hourly"
  description = "BIG-IQ license unit of measure"
}
variable "bigIqHypervisor" {
  type        = string
  default     = "azure"
  description = "BIG-IQ hypervisor"
}
variable "resourceOwner" {
  type        = string
  default     = null
  description = "This is a tag used for object creation. Example is last name."
}
variable "vm_name" {
  description = "Prefix for BIG-IP instance name. If empty, default is 'bigip' string + prefix + random_id"
  default     = ""
}
