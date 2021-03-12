# Variables

# AWS Environment
variable "awsRegion" { default = "us-west-2" }
variable "projectPrefix" { default = "mydemo" }
variable "resourceOwner" { default = "myname" }

# NETWORK
variable "vpcId" {}
variable "extSubnetAz1" {}
variable "extSubnetAz2" {}

# AWS LB, auto healing, and auto scaling
variable "asg_min_size" { default = 1 }
variable "asg_max_size" { default = 2 }
variable "asg_desired_capacity" { default = 1 }

# BIGIP Image
variable "f5_ami_search_name" { default = "F5 BIGIP-15.1.2.1* PAYG-Best 200Mbps*" }
variable "ec2_instance_type" { default = "m5.xlarge" }

# BIGIP Setup
variable "f5_username" { default = "admin" }
variable "f5_password" {}
variable "uSecret" { default = "my-secret" }
variable "ec2_key_name" {}
variable "allowedIps" {}
variable "ntp_server" { default = "169.254.169.123" }
variable "timezone" { default = "UTC" }
variable "DO_URL" { default = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.19.0/f5-declarative-onboarding-1.19.0-2.noarch.rpm" }
variable "onboard_log" { default = "/var/log/cloud/onboard.log" }

# BIGIQ License Manager Setup
variable "bigIqHost" { default = "200.200.200.200" }
variable "bigIqUsername" { default = "admin" }
variable "bigIqLicenseType" { default = "licensePool" }
variable "bigIqLicensePool" { default = "myPool" }
variable "bigIqSkuKeyword1" { default = "key1" }
variable "bigIqSkuKeyword2" { default = "key2" }
variable "bigIqUnitOfMeasure" { default = "hourly" }
variable "bigIqHypervisor" { default = "aws" }
