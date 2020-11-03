# Variables

# REST API Setting
variable rest_do_uri { default = "/mgmt/shared/declarative-onboarding" }
variable rest_as3_uri { default = "/mgmt/shared/appsvcs/declare" }
variable rest_do_method { default = "POST" }
variable rest_as3_method { default = "POST" }
variable rest_vm01_do_file { default = "vm01_do_data.json" }
variable rest_vm_as3_file { default = "vm_as3_data.json" }
variable rest_ts_uri { default = "/mgmt/shared/telemetry/declare" }
variable rest_vm_ts_file { default = "vm_ts_data.json" }

# Azure Environment
variable sp_subscription_id {}
variable sp_client_id {}
variable sp_client_secret {}
variable sp_tenant_id {}
variable prefix {}
variable location {}
variable storage_name {}

# NETWORK
variable vnet_rg {}
variable vnet_name {}
variable mgmtSubnet {}
variable extSubnet {}
variable intSubnet {}
variable f5vm01mgmt { default = "10.90.1.4" }
variable f5vm01ext { default = "10.90.2.4" }
variable f5privatevip { default = "10.90.2.11" }
variable f5publicvip { default = "10.90.2.12" }
variable backend01ext { default = "10.90.2.101" }
variable mgmt_gw { default = "10.90.1.1" }
variable ext_gw { default = "10.90.2.1" }

# BIGIP Image
variable instance_type { default = "Standard_DS4_v2" }
variable image_name { default = "f5-bigip-virtual-edition-25m-best-hourly" }
variable product { default = "f5-big-ip-best" }
variable bigip_version { default = "15.1.004000" }

# BIGIP Setup
variable uname {}
variable upassword {}
variable license1 { default = "" }
variable host1_name { default = "f5vm01" }
variable dns_server { default = "8.8.8.8" }
variable ntp_server { default = "0.us.pool.ntp.org" }
variable timezone { default = "UTC" }
variable DO_URL { default = "https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.16.0/f5-declarative-onboarding-1.16.0-8.noarch.rpm" }
variable AS3_URL { default = "https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.23.0/f5-appsvcs-3.23.0-5.noarch.rpm" }
variable TS_URL { default = "https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.15.0/f5-telemetry-1.15.0-4.noarch.rpm" }
variable libs_dir { default = "/config/cloud/azure/node_modules" }
variable onboard_log { default = "/var/log/startup-script.log" }

# TAGS
variable purpose { default = "public" }
variable environment { default = "f5env" } #ex. dev/staging/prod
variable owner { default = "f5owner" }
variable group { default = "f5group" }
variable costcenter { default = "f5costcenter" }
variable application { default = "f5app" }
