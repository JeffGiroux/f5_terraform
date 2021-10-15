variable "sp_subscription_id" {
  type        = string
  default     = ""
  description = "This is the service principal subscription ID"
}
variable "sp_client_id" {
  type        = string
  default     = ""
  description = "This is the service principal application/client ID"
}
variable "sp_client_secret" {
  type        = string
  default     = ""
  description = "This is the service principal secret"
}
variable "sp_tenant_id" {
  type        = string
  default     = ""
  description = "This is the service principal tenant ID"
}
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
variable "cidr" {
  type        = list(any)
  default     = ["10.0.0.0/16", "fd00:db8:deca::/48"]
  description = "Azure CIDR address space that is used by the virtual network"
}
variable "mgmtSubnetPrefix" {
  type        = list(any)
  default     = ["10.0.1.0/24"]
  description = "The address prefix to use for the managment subnet"
}
variable "externalSubnetPrefix" {
  type        = list(any)
  default     = ["10.0.10.0/24", "fd00:db8:deca:deed::/64"]
  description = "The address prefix to use for the external subnet"
}
variable "internalSubnetPrefix" {
  type        = list(any)
  default     = ["10.0.20.0/24", "fd00:db8:deca:dcba::/64"]
  description = "The address prefix to use for the internal subnet"
}
variable "backendSubnetPrefix" {
  type        = list(any)
  default     = ["10.0.40.0/24", "fd00:db8:deca:abcd::/64"]
  description = "The address prefix to use for the backend subnet"
}
variable "subnetNames" {
  type        = list(any)
  default     = ["mgmt", "external", "internal", "backend"]
  description = "The name to use for the subnet"
}
variable "backendPrivateIp4" {
  type        = string
  default     = "10.0.40.50"
  description = "The private IPv4 address for the backend machine"
}
variable "backendPrivateIp6" {
  type        = string
  default     = "fd00:db8:deca:abcd::50"
  description = "The private IPv6 address for the backend machine"
}
variable "backendInstanceType" {
  type        = string
  description = "Azure instance type to be used for the backend machine"
  default     = "Standard_B2ms"
}
variable "instance_type" {
  type        = string
  default     = "Standard_DS4_v2"
  description = "Azure instance type to be used for the BIG-IP VE"
}
variable "image_name" {
  type        = string
  default     = "f5-bigip-virtual-edition-1g-best-hourly"
  description = "F5 SKU (image) to deploy. Note: The disk size of the VM will be determined based on the option you select.  **Important**: If intending to provision multiple modules, ensure the appropriate value is selected, such as ****AllTwoBootLocations or AllOneBootLocation****."
}
variable "product" {
  type        = string
  default     = "f5-big-ip-best"
  description = "Azure BIG-IP VE Offer"
}
variable "bigip_version" {
  type        = string
  default     = "15.1.201000"
  description = "BIG-IP Version"
}
variable "bigipMgmtPrivateIp4" {
  type        = string
  default     = "10.0.1.10"
  description = "The private IPv4 address for the BIG-IP management NIC"
}
variable "bigipExtPrivateIp4" {
  type        = string
  default     = "10.0.10.10"
  description = "The private self IPv4 address for the BIG-IP external NIC"
}
variable "bigipExtPrivateIp6" {
  type        = string
  default     = "fd00:db8:deca:deed::10"
  description = "The private self IPv6 address for the BIG-IP external NIC"
}
variable "bigipExtSecondaryIp4" {
  type        = string
  default     = "10.0.10.11"
  description = "The private (secondary) IPv4 address for the BIG-IP external NIC used for the VIP (aka application)"
}
variable "bigipIntPrivateIp4" {
  type        = string
  default     = "10.0.20.10"
  description = "The private self IPv4 address for the BIG-IP internal NIC"
}
variable "bigipIntPrivateIp6" {
  type        = string
  default     = "fd00:db8:deca:dcba::10"
  description = "The private self IPv6 address for the BIG-IP internal NIC"
}
variable "bigipIntSecondaryIp4" {
  type        = string
  default     = "10.0.20.11"
  description = "The private (secondary) IPv4 address for the BIG-IP internal NIC"
}
variable "linkLocalAddress" {
  type        = string
  default     = "fe80::1234:5678:9abc"
  description = "The link local address RA for IPv6 default gateway in Azure"
}
variable "uname" {
  type        = string
  default     = "azureuser"
  description = "User name for the Virtual Machine"
}
variable "upassword" {
  type        = string
  default     = "Default12345!"
  description = "Password for the Virtual Machine"
}
variable "ssh_key" {
  type        = string
  description = "public key used for authentication in ssh-rsa format"
}
variable "license1" {
  type        = string
  default     = ""
  description = "The license token for the 1st F5 BIG-IP VE (BYOL)"
}
variable "dns_server" {
  type        = string
  default     = "8.8.8.8"
  description = "Leave the default DNS server the BIG-IP uses, or replace the default DNS server with the one you want to use"
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
  description = "URL to download the BIG-IP Declarative Onboarding module"
  type        = string
  default     = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.24.0/f5-declarative-onboarding-1.24.0-6.noarch.rpm"
}
variable "AS3_URL" {
  description = "URL to download the BIG-IP Application Service Extension 3 (AS3) module"
  type        = string
  default     = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.31.0/f5-appsvcs-3.31.0-6.noarch.rpm"
}
variable "TS_URL" {
  description = "URL to download the BIG-IP Telemetry Streaming module"
  type        = string
  default     = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.23.0/f5-telemetry-1.23.0-4.noarch.rpm"
}
variable "FAST_URL" {
  description = "URL to download the BIG-IP FAST module"
  type        = string
  default     = "https://github.com/F5Networks/f5-appsvcs-templates/releases/download/v1.12.0/f5-appsvcs-templates-1.12.0-1.noarch.rpm"
}
variable "INIT_URL" {
  description = "URL to download the BIG-IP runtime init"
  type        = string
  default     = "https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.3.2/dist/f5-bigip-runtime-init-1.3.2-1.gz.run"
}
variable "libs_dir" {
  description = "Directory on the BIG-IP to download the A&O Toolchain into"
  default     = "/config/cloud/azure/node_modules"
  type        = string
}
variable "onboard_log" {
  description = "Directory on the BIG-IP to store the cloud-init logs"
  default     = "/var/log/startup-script.log"
  type        = string
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
variable "owner" {
  type        = string
  default     = null
  description = "This is a tag used for object creation. Example is last name."
}
