# Variables

# Google Environment
variable svc_acct {}
variable privateKeyId {}
variable ksecret {}
variable gcp_project_id {}
variable gcp_region {}
variable gcp_zone {}
variable prefix {}

# NETWORK
variable extVpc {}
variable intVpc {}
variable mgmtVpc {}
variable extSubnet {}
variable intSubnet {}
variable mgmtSubnet {}

# BIGIP Image
variable bigipMachineType { default = "n1-standard-8" }
variable image_name { default = "projects/f5-7626-networks-public/global/images/f5-bigip-15-1-0-2-0-0-9-payg-best-1gbps-200321032524" }
variable customImage { default = "" }
variable customUserData { default = "" }

# BIGIP Setup
variable uname {}
variable usecret {}
variable license1 { default = "" }
variable license2 { default = "" }
variable adminSrcAddr {}
variable gceSshPubKey {}
variable host1_name { default = "f5vm01" }
variable host2_name { default = "f5vm02" }
variable dns_server { default = "8.8.8.8" }
variable dns_suffix {}
variable ntp_server { default = "0.us.pool.ntp.org" }
variable timezone { default = "UTC" }
variable DO_URL { default = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.13.0/f5-declarative-onboarding-1.13.0-5.noarch.rpm" }
variable AS3_URL { default = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.20.0/f5-appsvcs-3.20.0-3.noarch.rpm" }
variable TS_URL { default = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.12.0/f5-telemetry-1.12.0-3.noarch.rpm" }
variable onboard_log { default = "/var/log/cloud/onboard.log" }

# BIGIQ License Manager Setup
variable bigIqHost { default = "200.200.200.200" }
variable bigIqUsername { default = "admin" }
variable bigIqLicenseType { default = "licensePool" }
variable bigIqLicensePool { default = "myPool" }
variable bigIqSkuKeyword1 { default = "key1" }
variable bigIqSkuKeyword2 { default = "key1" }
variable bigIqUnitOfMeasure { default = "hourly" }
variable bigIqHypervisor { default = "gce" }

# TAGS
variable purpose { default = "public" }
variable environment { default = "f5env" } #ex. dev/staging/prod
variable owner { default = "f5owner" }
variable group { default = "f5group" }
variable costcenter { default = "f5costcenter" }
variable application { default = "f5app" }
