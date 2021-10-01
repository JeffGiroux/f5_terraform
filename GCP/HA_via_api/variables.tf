# Variables

variable "svc_acct" {
  type        = string
  default     = null
  description = "Service Account for VM instance"
}
variable "ksecret" {
  type        = string
  default     = ""
  description = "Contains the value of the 'svc_acct' private key. Currently used for BIG-IP telemetry streaming to Google Cloud Monitoring (aka StackDriver). If you are not using this feature, you do not need this secret in Secret Manager."
}
variable "privateKeyId" {
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
variable "gcp_zone" {
  type        = string
  default     = "us-west1-b"
  description = "GCP Zone for provider"
}
variable "prefix" {
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
variable "alias_ip_range" {
  type        = string
  default     = "10.1.10.100/32"
  description = "An array of alias IP ranges for the BIG-IP network interface (used for VIP traffic, SNAT IPs, etc)"
}
variable "managed_route1" {
  type        = string
  default     = "192.0.2.0/24"
  description = "A UDR route can used for testing managed-route failover. Enter address prefix like x.x.x.x/x."
}
variable "bigipMachineType" {
  type        = string
  default     = "n1-standard-8"
  description = "Google machine type to be used for the BIG-IP VE"
}
variable "image_name" {
  type        = string
  default     = "projects/f5-7626-networks-public/global/images/f5-bigip-15-1-2-1-0-0-10-payg-best-1gbps-210115161130"
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
variable "uname" {
  type        = string
  default     = "admin"
  description = "User name for the Virtual Machine"
}
variable "usecret" {
  type        = string
  default     = null
  description = "Used during onboarding to query the Google Cloud Secret Manager API and retrieve the admin password (use the secret name, not the secret value/password)"
}
variable "license1" {
  type        = string
  default     = ""
  description = "The license token for the first F5 BIG-IP VE (BYOL)"
}
variable "license2" {
  type        = string
  default     = ""
  description = "The license token for the second F5 BIG-IP VE (BYOL)"
}
variable "adminSrcAddr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "Trusted source network for admin access"
}
variable "gceSshPubKey" {
  type        = string
  default     = null
  description = "SSH public key for admin authentation"
}
variable "host1_name" {
  type        = string
  default     = "f5vm01"
  description = "Hostname for the first BIG-IP"
}
variable "host2_name" {
  type        = string
  default     = "f5vm02"
  description = "Hostname for the second BIG-IP"
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
  description = "If you would like to change the time zone the BIG-IP uses, enter the time zone you want to use. This is based on the tz database found in /usr/share/zoneinfo (see the full list [here](https://cloud.google.com/dataprep/docs/html/Supported-Time-Zone-Values_66194188)). Example values: UTC, US/Pacific, US/Eastern, Europe/London or Asia/Singapore."
}
variable "DO_URL" {
  type        = string
  default     = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.23.0/f5-declarative-onboarding-1.23.0-4.noarch.rpm"
  description = "URL to download the BIG-IP Declarative Onboarding module"
}
variable "AS3_URL" {
  type        = string
  default     = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.30.0/f5-appsvcs-3.30.0-5.noarch.rpm"
  description = "URL to download the BIG-IP Application Service Extension 3 (AS3) module"
}
variable "TS_URL" {
  type        = string
  default     = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.22.0/f5-telemetry-1.22.0-1.noarch.rpm"
  description = "URL to download the BIG-IP Telemetry Streaming module"
}
variable "CFE_URL" {
  description = "URL to download the BIG-IP Cloud Failover Extension module"
  type        = string
  default     = "https://github.com/F5Networks/f5-cloud-failover-extension/releases/download/v1.9.0/f5-cloud-failover-1.9.0-0.noarch.rpm"
}
variable "onboard_log" {
  type        = string
  default     = "/var/log/cloud/onboard.log"
  description = "This is where the onboarding script logs all the events"
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
variable "f5_cloud_failover_label" {
  type        = string
  default     = "mydeployment"
  description = "This is a tag used for F5 Cloud Failover Extension to identity which cloud objects to move during a failover event."
}
