# REST API Setting
variable rest_do_uri { default  = "/mgmt/shared/declarative-onboarding" }
variable rest_as3_uri { default = "/mgmt/shared/appsvcs/declare" }
variable rest_CF_uri { default = "/mgmt/shared/cloud-failover/declare" }
variable rest_do_method { default = "POST" }
variable rest_as3_method { default = "POST" }
variable rest_vm01_do_file {default = "vm01_do_data.json" }
variable rest_vm02_do_file {default = "vm02_do_data.json" }
variable rest_vm_as3_file {default = "vm_as3_data.json" }
variable rest_vm_failover_file {default = "vm_failover_data.json" }

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
variable prefix	{ default = "zludemo" }
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
variable managed_route1 { default = "0.0.0.0/0" }
variable f5vm01mgmt	{ default = "10.90.1.4" }
variable f5vm01ext	{ default = "10.90.2.4" }
variable f5vm02mgmt	{ default = "10.90.1.5" }
variable f5vm02ext	{ default = "10.90.2.5" }
variable f5privatevip   { default = "10.90.2.11" }
variable f5publicvip    { default = "10.90.2.12" }
variable backend01ext   { default = "10.90.2.101" }

# BIGIP Image
variable instance_type	{ default = "Standard_DS4_v2" }
variable image_name	{ default = "f5-bigip-virtual-edition-25m-best-hourly" }
variable product	{ default = "f5-big-ip-best" }
variable bigip_version	{ default = "latest" }

# BIGIP Setup
variable license1	      { default = ""}
variable license2	      { default = ""}
variable host1_name           { default = "f5vm01"}
variable host2_name           { default = "f5vm02"}
variable dns_server           { default = "8.8.8.8" }
variable ntp_server           { default = "0.us.pool.ntp.org" }
variable timezone             { default = "UTC" }
## Please check and update the latest DO URL from https://github.com/F5Networks/f5-declarative-onboarding/releases
variable DO_onboard_URL	      { default = "https://github.com/garyluf5/f5tools/raw/master/f5-declarative-onboarding-1.6.0-1.noarch.rpm" }
## Please check and update the latest AS3 URL from https://github.com/F5Networks/f5-appsvcs-extension/releases/latest 
variable AS3_URL	      { default = "https://github.com/garyluf5/f5tools/raw/master/f5-appsvcs-3.14.0-4.noarch.rpm" }
## Please check and update the latest Telemtry URL from https://github.com/F5Networks/f5-telemetry-streaming/tree/master/dist
variable TS_URL               { default = "https://github.com/garyluf5/f5tools/raw/master/f5-telemetry-1.5.0-1.noarch.rpm" }
## Please check and update the latest Cloud Failover RPM URL from https://clouddocs.f5networks.net/products/extensions/f5-cloud-failover/latest/
variable CF_URL	 	      { default = "" }
variable libs_dir	      { default = "/config/cloud/azure/node_modules" }
variable onboard_log	      { default = "/var/log/startup-script.log" }

# TAGS
variable purpose        { default = "public"       }
variable environment    { default = "f5env"        }  #ex. dev/staging/prod
variable owner          { default = "f5owner"      }
variable group          { default = "f5group"      }
variable costcenter     { default = "f5costcenter" }
variable application    { default = "f5app"        }
variable f5_cloud_failover_label { default = "mydeployment" }  #Cloud Failover Tag


