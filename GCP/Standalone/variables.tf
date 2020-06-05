
# BIG-IP

variable "projectPrefix" {
  description = "Prefix for resources created by this module"
  type        = string
  default     = "terraform-gcp-bigip-"
}
variable "buildSuffix" {
  description = "resource suffix"
}
variable "name" {
  description = "device name"
  default     = "bigip"
}
variable "instanceCount" {
  description = "number of devices"
  default     = 1
}
variable "bigipMachineType" {
  description = "BIG-IP GCE machine type/size"
  default     = "n1-standard-8"
}
variable "bigipImage" {
  description = " BIG-IP GCE image name"
  default     = "projects/f5-7626-networks-public/global/images/f5-bigip-15-1-0-2-0-0-9-payg-best-1gbps-200321032524"
}
variable adminAccountName {
  description = "BIG-IP admin account name"
}
variable adminPass {
  description = "BIG-IP admin password"
  default     = ""
}
variable "adminSrcAddr" {
  description = "admin source range in CIDR"
}
variable "gceSshPubKey" {
  description = "GCP GCE Key name for SSH access"
  type        = string
}
variable host1Name { default = "f5vm01" }
variable host2Name { default = "f5vm02" }
variable dnsServer { default = "8.8.8.8" }
variable ntpServer { default = "0.us.pool.ntp.org" }
variable timezone { default = "UTC" }
variable libsDir { default = "/config/cloud/gcp/node_modules" }
variable onboardLog { default = "/var/log/startup-script.log" }

# BIG-IP Custom image
variable "customImage" {
  description = "custom build image name"
  default     = ""
}
variable "customUserData" {
  description = "custom startup script data"
  default     = ""
}

# IAM
variable "serviceAccounts" {
  type = map(string)
  default = {
    storage = "default-compute@developer.gserviceaccount.com"
    compute = "default-compute@developer.gserviceaccount.com"
  }
}

#Provider 
variable "GCP_PROJECT_ID" {
  description = "project ID"
}
variable "GCP_REGION" {
  description = "region"
  default     = "us-east1"
}
variable "GCP_ZONE" {
  description = "zone"
  default     = "us-east1-b"
}

# Networks
# vpcs
variable "extVpc" {
  description = "name of external vpc"
}
variable "mgmtVpc" {
  description = "name of mgmt vpc"
}
variable "intVpc" {
  description = "name of internal vpc"
}
# subnets
variable "extSubnet" {
  description = "name of external subnet"
}
variable "mgmtSubnet" {
  description = "name of management subnet"
}
variable "intSubnet" {
  description = "name of internal subnet"
}
