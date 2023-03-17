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
variable "securityVpcCidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR IP Address range of the security VPC"
}
variable "securityMgmtSubnets" {
  type        = list(any)
  default     = ["10.0.1.0/24", "10.0.101.0/24"]
  description = "Management subnet address prefixes"
}
variable "securityExternalSubnets" {
  type        = list(any)
  default     = ["10.0.2.0/24", "10.0.102.0/24"]
  description = "External subnet address prefixes"
}
variable "securityInternalSubnets" {
  type        = list(any)
  default     = ["10.0.5.0/24", "10.0.105.0/24"]
  description = "Internal subnet address prefixes"
}
variable "securityDmz1Subnets" {
  type        = list(any)
  default     = ["10.0.3.0/25", "10.0.103.0/25"]
  description = "DMZ1 subnet address prefixes for decryption zone"
}
variable "securityDmz2Subnets" {
  type        = list(any)
  default     = ["10.0.3.128/25", "10.0.103.128/25"]
  description = "DMZ2 subnet address prefixes for decryption zone"
}
variable "securityDmz3Subnets" {
  type        = list(any)
  default     = ["10.0.4.0/25", "10.0.104.0/25"]
  description = "DMZ3 subnet address prefixes for decryption zone"
}
variable "securityDmz4Subnets" {
  type        = list(any)
  default     = ["10.0.4.128/25", "10.0.104.128/25"]
  description = "DMZ4 subnet address prefixes for decryption zone"
}
variable "securityGwlbSubnets" {
  type        = list(any)
  default     = ["10.0.255.0/25", "10.0.255.128/25"]
  description = "GWLB subnet address prefixes"
}
variable "applicationVpcCidr" {
  type        = string
  default     = "192.168.0.0/16"
  description = "CIDR IP Address range of the application VPC"
}
variable "applicationPrivateSubnets" {
  type        = list(any)
  default     = ["192.168.1.0/24", "192.168.101.0/24"]
  description = "Private subnet address prefixes"
}
variable "applicationGwlbeSubnets" {
  type        = list(any)
  default     = ["192.168.2.0/25", "192.168.2.128/25"]
  description = "GWLB endpoint subnet address prefixes"
}
variable "f5_ami_search_name" {
  type        = string
  description = "AWS AMI search filter to find correct BIG-IP VE for region"
  default     = "F5 BIGIP-16.1.3.3* BYOL-All* 2Boot*"
}
variable "ec2_instance_type" {
  type        = string
  description = "AWS instance type for the BIG-IP. Ensure that you use an instance type that supports the 7 ENIs required for this deployment. This will usually be some variant of a **4xlarge** instance type."
  default     = "m5.4xlarge"
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
variable "ssh_key" {
  type        = string
  description = "public key used for authentication in ssh-rsa format"
}
variable "license_sslo" {
  type        = string
  default     = ""
  description = "The license token for the BIG-IP SSL Orchestrator (BYOL)"
}
variable "license_ips" {
  type        = string
  default     = ""
  description = "The license token for the BIG-IP IPS Insepection device (BYOL)"
}
variable "sslo_pkg_name" {
  description = "SSL Orchestrator built-in RPM package name (dependent on BIG-IP version)"
  type        = string
  default     = "f5-iappslx-ssl-orchestrator-16.1.3-9.3.41.noarch.rpm"
}
variable "webapp_ami_search_name" {
  type        = string
  description = "AWS AMI search filter to find correct web app (Wordpress) for region"
  default     = "bitnami-wordpress-6.1.1-53-r54-linux-debian-11*"
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
  description = "URL to download the BIG-IP FAST module"
  type        = string
  default     = "https://github.com/F5Networks/f5-appsvcs-templates/releases/download/v1.24.0/f5-appsvcs-templates-1.24.0-1.noarch.rpm"
}
variable "INIT_URL" {
  description = "URL to download the BIG-IP runtime init"
  type        = string
  default     = "https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.6.0/dist/f5-bigip-runtime-init-1.6.0-1.gz.run"
}
variable "libs_dir" {
  description = "Directory on the BIG-IP to download the A&O Toolchain into"
  default     = "/config/cloud/aws/node_modules"
  type        = string
}
variable "resourceOwner" {
  type        = string
  description = "owner of the deployment, for tagging purposes"
  default     = "myName"
}
