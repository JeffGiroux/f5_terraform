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
variable mgmtVpc {}
variable extSubnet {}
variable mgmtSubnet {}
variable alias_ip_range { default = "10.1.10.100/32" }
variable managed_route1 { default = "0.0.0.0/0" }

# BIGIP Image
variable bigipMachineType { default = "n1-standard-8" }
variable image_name { default = "projects/f5-7626-networks-public/global/images/f5-bigip-15-1-0-2-0-0-9-payg-best-1gbps-200321032524" } # BIG-IP Custom image
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
variable CF_URL { default = "https://github.com/F5Networks/f5-cloud-failover-extension/releases/download/v1.3.0/f5-cloud-failover-1.3.0-0.noarch.rpm" }
variable onboard_log { default = "/var/log/cloud/onboard.log" }

# TAGS
variable purpose { default = "public" }
variable environment { default = "f5env" } #ex. dev/staging/prod
variable owner { default = "f5owner" }
variable group { default = "f5group" }
variable costcenter { default = "f5costcenter" }
variable application { default = "f5app" }
variable f5_cloud_failover_label { default = "mydeployment" } #Cloud Failover Tag
variable f5_cloud_failover_nic_map { default = "external" }   #NIC Tag
