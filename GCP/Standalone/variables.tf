# Variables

variable "svc_acct" {
  type        = string
  default     = null
  description = "Service Account for VM instance"
}
variable "telemetry_secret" {
  type        = string
  default     = ""
  description = "Contains the value of the 'svc_acct' private key. Currently used for BIG-IP telemetry streaming to Google Cloud Monitoring (aka StackDriver). If you are not using this feature, you do not need this secret in Secret Manager."
}
variable "telemetry_privateKeyId" {
  type        = string
  default     = ""
  description = "ID of private key for the 'svc_acct' used in Telemetry Streaming to Google Cloud Monitoring. If you are not using this feature, you do not need this secret in Secret Manager."
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
variable "projectPrefix" {
  type        = string
  default     = "demo"
  description = "This value is inserted at the beginning of each Google object (alpha-numeric, no special character)"
}
variable "extVpc" {
  type        = string
  default     = null
  description = "External VPC network"
}
variable "intVpc" {
  type        = string
  default     = null
  description = "Internal VPC network"
}
variable "mgmtVpc" {
  type        = string
  default     = null
  description = "Management VPC network"
}
variable "extSubnet" {
  type        = string
  default     = null
  description = "External subnet"
}
variable "intSubnet" {
  type        = string
  default     = null
  description = "Internal subnet"
}
variable "mgmtSubnet" {
  type        = string
  default     = null
  description = "Management subnet"
}
variable "machine_type" {
  type        = string
  default     = "n1-standard-8"
  description = "Google machine type to be used for the BIG-IP VE"
}
variable "image_name" {
  type        = string
  default     = "projects/f5-7626-networks-public/global/images/f5-bigip-16-1-3-0-0-12-payg-best-plus-200mbps-220607234640"
  description = "F5 SKU (image) to deploy. Note: The disk size of the VM will be determined based on the option you select.  **Important**: If intending to provision multiple modules, ensure the appropriate value is selected, such as ****AllTwoBootLocations or AllOneBootLocation****."
}
variable "customImage" {
  type        = string
  default     = ""
  description = "A custom SKU (image) to deploy that you provide. This is useful if you created your own BIG-IP image with the F5 image creator tool."
}
variable "customUserData" {
  type        = string
  default     = ""
  description = "The custom user data to deploy when using the 'customImage' paramater too."
}
variable "f5_username" {
  type        = string
  default     = "admin"
  description = "User name for the Virtual Machine"
}
variable "f5_password" {
  type        = string
  default     = null
  description = "Password for the Virtual Machine"
}
variable "gcp_secret_manager_authentication" {
  description = "Whether to use secret manager to pass authentication"
  type        = bool
  default     = false
}
variable "license1" {
  type        = string
  default     = ""
  description = "The license token for the first F5 BIG-IP VE (BYOL)"
}
variable "adminSrcAddr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "Trusted source network for admin access"
}
variable "ssh_key" {
  type        = string
  default     = null
  description = "Path to the public key to be used for ssh access to the VM.  Only used with non-Windows vms and can be left as-is even if using Windows vms. If specifying a path to a certification on a Windows machine to provision a linux vm use the / in the path versus backslash. e.g. c:/home/id_rsa.pub"
}
variable "dns_server" {
  type        = string
  default     = "169.254.169.254"
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
  description = "If you would like to change the time zone the BIG-IP uses, enter the time zone you want to use. This is based on the tz database found in /usr/share/zoneinfo (see the full list [here](https://cloud.google.com/dataprep/docs/html/Supported-Time-Zone-Values_66194188)). Example values: UTC, US/Pacific, US/Eastern, Europe/London or Asia/Singapore."
}
variable "DO_URL" {
  type        = string
  default     = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.30.0/f5-declarative-onboarding-1.30.0-3.noarch.rpm"
  description = "URL to download the BIG-IP Declarative Onboarding module"
}
variable "AS3_URL" {
  type        = string
  default     = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.36.1/f5-appsvcs-3.36.1-1.noarch.rpm"
  description = "URL to download the BIG-IP Application Service Extension 3 (AS3) module"
}
variable "TS_URL" {
  type        = string
  default     = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.29.0/f5-telemetry-1.29.0-1.noarch.rpm"
  description = "URL to download the BIG-IP Telemetry Streaming module"
}
variable "FAST_URL" {
  description = "URL to download the BIG-IP FAST module"
  type        = string
  default     = "https://github.com/F5Networks/f5-appsvcs-templates/releases/download/v1.19.0/f5-appsvcs-templates-1.19.0-1.noarch.rpm"
}
variable "INIT_URL" {
  description = "URL to download the BIG-IP runtime init"
  type        = string
  default     = "https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.5.0/dist/f5-bigip-runtime-init-1.5.0-1.gz.run"
}
variable "bigIqHost" {
  type        = string
  default     = ""
  description = "This is the BIG-IQ License Manager host name or IP address"
}
variable "bigIqUsername" {
  type        = string
  default     = "admin"
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
  default     = "gce"
  description = "BIG-IQ hypervisor"
}
variable "owner" {
  type        = string
  default     = null
  description = "This is a tag used for object creation. Example is last name."
}
