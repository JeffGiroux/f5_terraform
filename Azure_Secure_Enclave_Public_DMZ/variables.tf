# REST API Setting
variable rest_do_uri { default	= "/mgmt/shared/declarative-onboarding" }
variable rest_as3_uri { default = "/mgmt/shared/appsvcs/declare" }
variable rest_do_method { default = "POST" }
variable rest_as3_method { default = "POST" }
variable rest_vm01_do_file {default = "vm01_do_data.json" }
variable rest_vm02_do_file {default = "vm02_do_data.json" }
variable rest_vm_as3_file {default = "vm_as3_data.json" }

# Azure Environment
variable "SP" {
        type = "map"
        default = {
                subscription_id = "xxxxx"
                client_id       = "xxxxx"
                client_secret   = "xxxxx"
                tenant_id       = "xxxxx"
        }
}
variable prefix	{ default = "zlusca" }
variable uname	{ default = "azureuser" }
variable upassword	{ default = "Default12345" }
variable location	{ default = "eastus" }	 
variable region		{ default = "East US" }

# NETWORK
variable cidr	{ default = "10.90.0.0/16" }
variable "subnets" {
	type = "map"
	default = {
		"subnet1" = "10.90.1.0/24"
		"subnet2" = "10.90.2.0/24"
		"subnet3" = "10.90.3.0/24"
	}
}
variable app-cidr   { default = "10.80.0.0/16" }
variable "app-subnets" {
        type = "map"
        default = {
                "subnet1" = "10.80.1.0/24"
        }
}
variable f5vm01mgmt	{ default = "10.90.1.4" }
variable f5vm01ext	{ default = "10.90.2.4" }
variable f5vm01ext_sec  { default = "10.90.2.11" }
variable f5vm01tosrv    { default = "198.19.0.41" }
# f5vm01tosrvfl's last octet needs to be higher than f5vm01tosrv's last octet (we want to automap to selfIP not floatingIP)
variable f5vm01tosrvfl  { default = "198.19.0.51" }
variable f5vm01frsrv    { default = "198.19.0.141" }
# f5vm01frsrvfl's last octet needs to be higher than f5vm01frsrv's last octet (we want to automap to selfIP not floatingIP)
variable f5vm01frsrvfl  { default = "198.19.0.151" }
variable f5vm02mgmt	{ default = "10.90.1.5" }
variable f5vm02ext	{ default = "10.90.2.5" }
variable f5vm02ext_sec  { default = "10.90.2.12" }
variable f5vm02tosrv    { default = "198.19.0.42" }
# f5vm02tosrvfl's last octet needs to be higher than  f5vm02tosrv's last octet (we want to automap to selfIP not floatingIP)
variable f5vm02tosrvfl  { default = "198.19.0.52" }
variable f5vm02frsrv    { default = "198.19.0.142" }
# f5vm02frsrvfl's last octet needs to be higher than  f5vm02frsrv's last octet (we want to automap to selfIP not floatingIP)
variable f5vm02frsrvfl  { default = "198.19.0.152" }
variable backend01ext   { default = "10.80.1.101" }
variable l3fwmgmt       { default = "10.90.1.60" }
variable l3fwuntrust    { default = "198.19.0.60" }
variable l3fwtrust      { default = "198.19.0.160" }

# BIGIP Image
variable instance_type	{ default = "Standard_DS4_v2" }
variable image_name	{ default = "f5-big-all-2slot-byol" }
variable product	{ default = "f5-big-ip-byol" }
variable bigip_version	{ default = "latest" }

# BIGIP Setup
## These licenses have been tested with F5-BIG-LTM-VE-1G-V16 base SKU 
variable license1             { default = "xxxxx" }
variable license2             { default = "xxxxx" }
variable host1_name           { default = "f5vm01" }
variable host2_name           { default = "f5vm02" }
variable dns_server           { default = "8.8.8.8" }
variable ntp_server           { default = "0.us.pool.ntp.org" }
variable timezone             { default = "UTC" }
## Please check and update the latest DO URL from https://github.com/F5Networks/f5-declarative-onboarding/releases
variable DO_onboard_URL	      { default = "https://github.com/garyluf5/f5tools/raw/master/f5-declarative-onboarding-1.6.0-1.noarch.rpm" }
## Please check and update the latest AS3 URL from https://github.com/F5Networks/f5-appsvcs-extension/releases/latest 
variable AS3_URL	      { default = "https://github.com/garyluf5/f5tools/raw/master/f5-appsvcs-3.13.0-3.noarch.rpm" }
## Please check and update the latest Telemetry Streaming from https://github.com/F5Networks/f5-telemetry-streaming/tree/master/dist
variable TS_URL	      	      { default = "https://github.com/garyluf5/f5tools/raw/master/f5-telemetry-1.5.0-1.noarch.rpm" }
variable libs_dir	      { default = "/config/cloud/azure/node_modules" }
variable onboard_log	      { default = "/var/log/startup-script.log" }

# TAGS
variable purpose        { default = "public"       }
variable environment    { default = "f5env"        }  #ex. dev/staging/prod
variable owner          { default = "f5owner"      }
variable group          { default = "f5group"      }
variable costcenter     { default = "f5costcenter" }
variable application    { default = "f5app"        }

