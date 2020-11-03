# Variables

# Azure Environment
variable sp_subscription_id {}
variable sp_client_id {}
variable sp_client_secret {}
variable sp_tenant_id {}
variable prefix {}
variable uname {}
variable upassword {}
variable location {}

# NETWORK
variable cidr { default = "10.90.0.0/16" }
variable "subnets" {
  type = map
  default = {
    "subnet1" = "10.90.1.0/24"
    "subnet2" = "10.90.2.0/24"
    "subnet3" = "10.90.3.0/24"
  }
}
variable backend01ext { default = "10.90.2.101" }
variable ext_gw { default = "10.90.2.1" }

# BIGIP Image
variable instance_type { default = "Standard_DS4_v2" }
variable image_name { default = "f5-bigip-virtual-edition-25m-best-hourly" }
variable product { default = "f5-big-ip-best" }
variable bigip_version { default = "15.1.004000" }

# BIGIP Setup
variable dns_server { default = "8.8.8.8" }
variable ntp_server { default = "0.us.pool.ntp.org" }
variable timezone { default = "UTC" }
variable DO_URL { default = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.16.0/f5-declarative-onboarding-1.16.0-8.noarch.rpm" }
variable AS3_URL { default = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.23.0/f5-appsvcs-3.23.0-5.noarch.rpm" }
variable TS_URL { default = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.15.0/f5-telemetry-1.15.0-4.noarch.rpm" }
variable libs_dir { default = "/config/cloud/azure/node_modules" }
variable onboard_log { default = "/var/log/startup-script.log" }

# BIGIQ License Manager Setup
variable bigIqHost { default = "200.200.200.200" }
variable bigIqUsername {}
variable bigIqPassword {}
variable bigIqLicenseType { default = "licensePool" }
variable bigIqLicensePool { default = "myPool" }
variable bigIqSkuKeyword1 { default = "key1" }
variable bigIqSkuKeyword2 { default = "key1" }
variable bigIqUnitOfMeasure { default = "hourly" }
variable bigIqHypervisor { default = "azure" }

# TAGS
variable purpose { default = "public" }
variable environment { default = "f5env" } #ex. dev/staging/prod
variable owner { default = "f5owner" }
variable group { default = "f5group" }
variable costcenter { default = "f5costcenter" }
variable application { default = "f5app" }
