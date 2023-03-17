# Variables

variable "projectPrefix" {
  type        = string
  default     = "demo"
  description = "This value is inserted at the beginning of each AWS object (alpha-numeric, no special character)"
}
variable "awsRegion" {
  description = "aws region"
  type        = string
  default     = "us-west-2"
}
variable "awsAz1" {
  description = "Availability zone, will dynamically choose one if left empty"
  type        = string
  default     = "us-west-2a"
}
variable "awsAz2" {
  description = "Availability zone, will dynamically choose one if left empty"
  type        = string
  default     = "us-west-2b"
}
variable "adminSrcAddr" {
  type        = string
  description = "Allowed Admin source IP prefix"
  default     = "0.0.0.0/0"
}
variable "vpcId" {
  type        = string
  description = "The AWS network VPC ID"
  default     = null
}
variable "mgmtSubnetAz1" {
  type        = string
  description = "ID of Management subnet AZ1"
  default     = null
}
variable "mgmtSubnetAz2" {
  type        = string
  description = "ID of Management subnet AZ2"
  default     = null
}
variable "extSubnetAz1" {
  type        = string
  description = "ID of External subnet AZ1"
  default     = null
}
variable "extSubnetAz2" {
  type        = string
  description = "ID of External subnet AZ2"
  default     = null
}
variable "intSubnetAz1" {
  type        = string
  description = "ID of Internal subnet AZ1"
  default     = null
}
variable "intSubnetAz2" {
  type        = string
  description = "ID of Internal subnet AZ2"
  default     = null
}
variable "mgmtNsg" {
  type        = string
  description = "ID of management security group"
  default     = null
}
variable "extNsg" {
  type        = string
  description = "ID of external security group"
  default     = null
}
variable "intNsg" {
  type        = string
  description = "ID of internal security group"
  default     = null
}
variable "cfe_managed_route" {
  type        = string
  description = "A route can used for testing managed-route failover. Enter address prefix like x.x.x.x/x"
  default     = "0.0.0.0/0"
}
variable "f5_ami_search_name" {
  type        = string
  description = "AWS AMI search filter to find correct BIG-IP VE for region"
  default     = "F5 BIGIP-16.1.3.2* PAYG-Best Plus 200Mbps*"
}
variable "ec2_instance_type" {
  type        = string
  description = "AWS instance type for the BIG-IP"
  default     = "m5n.xlarge"
}
variable "ec2_key_name" {
  type        = string
  description = "AWS EC2 Key name for SSH access"
  default     = null
}
variable "f5_username" {
  type        = string
  description = "User name for the BIG-IP (Note: currenlty not used. Defaults to 'admin' based on AMI"
  default     = "admin"
}
variable "f5_password" {
  type        = string
  description = "BIG-IP Password or Secret ARN (value should be ARN of secret when aws_secretmanager_auth = true, ex. arn:aws:secretsmanager:us-west-2:1234:secret:bigip-secret-abcd)"
  default     = "Default12345!"
}
variable "aws_secretmanager_auth" {
  description = "Whether to use secret manager to pass authentication"
  type        = bool
  default     = false
}
variable "aws_secretmanager_secret_id" {
  description = "The ARN of Secrets Manager secret with BIG-IP password"
  type        = string
  default     = null
}
variable "aws_iam_instance_profile" {
  description = "Name of IAM role to assign to the BIG-IP instance"
  type        = string
  default     = null
}
variable "license1" {
  type        = string
  default     = ""
  description = "The license token for the 1st F5 BIG-IP VE (BYOL)"
}
variable "license2" {
  type        = string
  default     = ""
  description = "The license token for the 2nd F5 BIG-IP VE (BYOL)"
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
variable "CFE_URL" {
  description = "URL to download the BIG-IP Cloud Failover Extension module"
  type        = string
  default     = "https://github.com/F5Networks/f5-cloud-failover-extension/releases/download/v1.14.0/f5-cloud-failover-1.14.0-0.noarch.rpm"
}
variable "INIT_URL" {
  type        = string
  default     = "https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.6.0/dist/f5-bigip-runtime-init-1.6.0-1.gz.run"
  description = "URL to download the BIG-IP runtime init"
}
variable "libs_dir" {
  type        = string
  default     = "/config/cloud/aws/node_modules"
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
  default     = "aws"
  description = "BIG-IQ hypervisor"
}
variable "resourceOwner" {
  type        = string
  default     = null
  description = "This is a tag used for object creation. Example is last name."
}
variable "f5_cloud_failover_label" {
  type        = string
  default     = "myFailover"
  description = "This is a tag used for F5 Cloud Failover extension. Must match value of 'f5_cloud_failover_label' in externalnic_failover_tags and internalnic_failover_tags."
}
