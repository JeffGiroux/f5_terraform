# Variables

# AWS Environment
variable "awsRegion" { default = "us-west-2" }
variable "projectPrefix" { default = "mydemo" }
variable "resourceOwner" { default = "myname" }

# NETWORK
variable "vpcId" {}
variable "mgmtSubnetAz1" {}
variable "mgmtSubnetAz2" {}
variable "extSubnetAz1" {}
variable "extSubnetAz2" {}
variable "intSubnetAz1" {}
variable "intSubnetAz2" {}
variable "mgmtNsg" {}
variable "extNsg" {}
variable "intNsg" {}
variable "cfe_managed_route" { default = "0.0.0.0/0" }
variable "allowedIps" {}

# BIGIP Image
variable "f5_ami_search_name" { default = "F5 BIGIP-15.1.2.1* PAYG-Best 200Mbps*" }
variable "ec2_instance_type" { default = "m5.xlarge" }

# BIGIP Setup
variable "f5_username" { default = "admin" }
variable "f5_password" { default = "Default12345!" }
variable "ssh_key" {
  type        = string
  description = "public key used for authentication in ssh-rsa format"
}
variable "license1" { default = "" }
variable "license2" { default = "" }
variable "dns_server" { default = "8.8.8.8" }
variable "ntp_server" { default = "0.us.pool.ntp.org" }
variable "timezone" { default = "UTC" }

variable "DO_URL" {
  description = "URL to download the BIG-IP Declarative Onboarding module"
  type        = string
  default     = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.23.0/f5-declarative-onboarding-1.23.0-4.noarch.rpm"
}
variable "AS3_URL" {
  description = "URL to download the BIG-IP Application Service Extension 3 (AS3) module"
  type        = string
  default     = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.30.0/f5-appsvcs-3.30.0-5.noarch.rpm"
}
variable "TS_URL" {
  description = "URL to download the BIG-IP Telemetry Streaming module"
  type        = string
  default     = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.22.0/f5-telemetry-1.22.0-1.noarch.rpm"
}
variable "FAST_URL" {
  description = "URL to download the BIG-IP FAST module"
  type        = string
  default     = "https://github.com/F5Networks/f5-appsvcs-templates/releases/download/v1.11.0/f5-appsvcs-templates-1.11.0-1.noarch.rpm"
}
variable "CFE_URL" {
  description = "URL to download the BIG-IP Cloud Failover Extension module"
  type        = string
  default     = "https://github.com/F5Networks/f5-cloud-failover-extension/releases/download/v1.9.0/f5-cloud-failover-1.9.0-0.noarch.rpm"
}
variable "INIT_URL" {
  description = "URL to download the BIG-IP runtime init"
  type        = string
  default     = "https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.2.1/dist/f5-bigip-runtime-init-1.2.1-1.gz.run"
}
variable "libs_dir" {
  description = "Directory on the BIG-IP to download the A&O Toolchain into"
  default     = "/config/cloud/aws/node_modules"
  type        = string
}
variable "onboard_log" {
  description = "Directory on the BIG-IP to store the cloud-init logs"
  default     = "/var/log/startup-script.log"
  type        = string
}

# BIGIQ License Manager Setup
variable "bigIqHost" { default = "200.200.200.200" }
variable "bigIqUsername" { default = "admin" }
variable "bigIqPassword" { default = "Default12345!" }
variable "bigIqLicenseType" { default = "licensePool" }
variable "bigIqLicensePool" { default = "myPool" }
variable "bigIqSkuKeyword1" { default = "key1" }
variable "bigIqSkuKeyword2" { default = "key2" }
variable "bigIqUnitOfMeasure" { default = "hourly" }
variable "bigIqHypervisor" { default = "aws" }
