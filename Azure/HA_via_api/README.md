# Deploying BIG-IP VEs in Azure - High Availability (Active/Standby): Two NICs

## Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Important Configuration Notes](#important-configuration-notes)
- [Security](#security)
- [Installation Example](#installation-example)
- [Configuration Example](#configuration-example)

## Introduction

This solution uses an Terraform template to launch a two NIC deployment of a cloud-focused BIG-IP VE cluster (Active/Standby) in Microsoft Azure. Traffic flows to the HA BIG-IP VE which then flows to DVWA app server. This is the standard cloud design where the BIG-IP VE instance is running with a dual interface, and both management and data plane traffic is processed on each separate NIC.  

The BIG-IP VEs have the [Local Traffic Manager (LTM)](https://f5.com/products/big-ip/local-traffic-manager-ltm) and [Application Security Module (ASM)](https://www.f5.com/products/security/advanced-waf) modules enabled to provide advanced traffic management functionality. This means you can also configure the BIG-IP VE to enable F5's L4/L7 security features, access control, Advance WAF and intelligent traffic management.

Terraform is beneficial as it allows composing resources a bit differently to account for dependencies into Immutable/Mutable elements. For example, mutable  includes items you would typically frequently change/mutate, such as traditional configs on the BIG-IP. Once the template is deployed, there are certain resources (network infrastructure) that are fixed while others (BIG-IP VMs and configurations) can be changed.

Example...

-> Run once
- Deploy the entire infrastructure with all the neccessary resources, then use Declarative Onboarding (DO) to configure the BIG-IP cluster, Application Services (AS3) to create a sample app proxy, then lastly use Service Discovery to automatically add the DVWA container app to the BIG-IP pool.

-> Run many X
- [Redeploy BIG-IP for replacement or upgrade](#Redeploy-BIG-IP-for-replacement-or-upgrade)
- [Reconfigure BIG-IP L1-L3 configurations (DO)](#Rerun-Declarative-Onboarding-on-the-BIG-IP-VE)
- [Reconfigure BIG-IP L4-L7 configurations (AS3)](#Rerun-Application-Services-AS3-on-the-BIG-IP-VE)
- [Reconfigure BIG-IP Cloud Failover Extension (CFE)](#Rerun-Cloud-Failover-Extension-on-the-BIG-IP-VE)

**Networking Stack Type:** This solution deploys into a new networking stack, which is created along with the solution.

## Version
This template is tested and worked in the following version
Terraform v0.12.23
+ provider.azurerm v2.1
+ provider.local v1.4
+ provider.null v2.1
+ provider.template v2.1

## Prerequisites

- **Important**: When you configure the admin password for the BIG-IP VE in the template, you cannot use the character **#**.  Additionally, there are a number of other special characters that you should avoid using for F5 product user accounts.  See [K2873](https://support.f5.com/csp/article/K2873) for details.
- This template requires a service principal for backend pool service discovery. **Important**: you MUST have "OWNER" priviledge on the SP in order to assign role to the resources in your subscription. See the [Service Principal Setup section](#service-principal-authentication) for details, including required permissions.
- The HA BIG-IP VMs use Azure RBAC role for the failover instead of using Service Prinicipal.
- These BIG-IP VMs are deployed across different Availability Zones. Please ensure the region you've chosen can support AZ.
- This deployment will be using the Terraform Azurerm provider to build out all the neccessary Azure objects. Therefore, Azure CLI is required. For installation, please follow this [Microsoft link](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest)
- If this is the first time to deploy the F5 image, the subscription used in this deployment needs to be enabled to programatically deploy. For more information, please refer to [Configure Programatic Deployment](https://azure.microsoft.com/en-us/blog/working-with-marketplace-images-on-azure-resource-manager/)

## Important configuration notes

- Variables are configured in variables.tf
- Sensitive variables like Azure Subscription and Service Principal are configured in terraform.tfvars
  - Note: Passwords and secrets will be moved to Azure Key Vault in the future
- This template uses Declarative Onboarding (DO), Application Services 3 (AS3), and Cloud Failover Extension packages for the initial configuration. As part of the onboarding script, it will download the RPMs automatically. See the [AS3 documentation](https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/) and [DO documentation](https://clouddocs.f5.com/products/extensions/f5-declarative-onboarding/latest/) for details on how to use AS3 and Declarative Onboarding on your BIG-IP VE(s). The [Cloud Failover Extension](https://clouddocs.f5.com/products/extensions/f5-cloud-failover/latest/) documentation is also available. The [Telemetry Streaming](https://clouddocs.f5.com/products/extensions/f5-telemetry-streaming/latest/) extension is also downloaded but not configured to point to any remote analytics/consumers. 
- onboard.tpl is the onboarding script which is run by commandToExecute (user data). It will be copied to /var/lib/waagent/CustomData upon bootup. This script is responsible for downloading the neccessary F5 Automation Toolchain RPM files, installing them, and then executing the onboarding REST calls.
- This template uses PayGo BIGIP image for the deployment (as default). If you would like to use BYOL, then these following steps are needed:
1. In the "variables.tf", specify the BYOL image and licenses regkeys.
2. In the "main.tf", uncomment the "local_sku" lines.
3. To find available images/versions, use this search example on Azure CLI:
  ```
          az vm image list -f BIG-IP --all
  ```
4. Add the following lines to the "cluster.json" file just under the "Common" declaration:
  ```
          "myLicense": {
            "class": "License",
            "licenseType": "regKey",
            "regKey": "${local_sku}"
          },
  ```
- In order to pass traffic from your clients to the servers after launching the template, you must create virtual server(s) on the BIG-IP VE.  See [Creating a virtual server](#creating-virtual-servers-on-the-big-ip-ve).
- See the **[Configuration Example](#configuration-example)** section for a configuration diagram and description for this solution.

### Template parameters

| Parameter | Required | Description |
| --- | --- | --- |
| prefix | Yes | This value is inserted in the beginning of each Azure object. Note: requires alpha-numeric without special character |
| rest_do_uri | Yes | URI of the Declarative Onboarding REST call. |
| rest_as3_uri | Yes | URI of the AS3 REST call. |
| rest_cf_uri | Yes | URI of the Cloud Failover REST call. |
| rest_do_method | Yes | Available options are GET, POST, and DELETE. |
| rest_as3_method | Yes | Available options are GET, POST, and DELETE. |
| rest_vm01_do_file | Yes | Terraform will generate the vm01 Declarative Onboarding (DO) json file. |
| rest_vm02_do_file | Yes | Terraform will generate the vm02 Declarative Onboarding (DO) json file. |
| rest_vm_as3_file | Yes | Terraform will generate the AS3 json file. |
| rest_vm_cf_file | Yes | Terraform will generate the Cloud Failover json file. |
| SP | YES | This is the service principal of the Azure subscription. |
| uname | Yes | User name for the Virtual Machine. |
| upassword | Yes | Password for the Virtual Machine. |
| location | Yes | Region/Location of the deployment. |
| cidr | Yes | IP Address range of the Virtual Network. |
| subnet1 | Yes | Subnet IP range of the management network. |
| subnet2 | Yes | Subnet IP range of the external network. |
| subnet3 | No | Subnet IP range of the internal network. |
| managed_route1 | Yes | A UDR route can used for testing managed-route failover. Enter address prefix like x.x.x.x/x. |
| f5vm01mgmt | Yes | IP address for 1st BIG-IP's management interface. |
| f5vm02mgmt | Yes | IP address for 2nd BIG-IP's management interface. |
| f5vm01ext | Yes | IP address for 1st BIG-IP's external interface. |
| f5vm01ext_sec | Yes | Secondary IP address for 1st BIG-IP's external interface. |
| f5vm02ext | Yes | IP address for 2nd BIG-IP's external interface. |
| f5vm02ext_sec | Yes | Secondary IP address for 2nd BIG-IP's external interface. |
| instance_type | Yes | Azure instance to be used for the BIG-IP VE. |
| product | Yes | Azure BIG-IP VE Offer. |
| bigip_version | Yes | It is set to default to use the latest software. |
| image_name | Yes | F5 SKU (image) to you want to deploy. Note: The disk size of the VM will be determined based on the option you select.  **Important**: If intending to provision multiple modules, ensure the appropriate value is selected, such as ****AllTwoBootLocations or AllOneBootLocation****. |
| license1 | No | The license token for the F5 BIG-IP VE (BYOL). |
| license2 | No | The license token for the F5 BIG-IP VE (BYOL). |
| host1_name | Yes | Hostname for the 1st BIG-IP. |
| host2_name | Yes | Hostname for the 2nd BIG-IP. |
| ntp_server | Yes | Leave the default NTP server (used by BIG-IP), or replace the default NTP server with the one you want to use. |
| timezone | Yes | If you would like to change the time zone on the BIG-IP, enter the time zone you want to use. This is based on the tz database found in /usr/share/zoneinfo (see the full list [here](https://github.com/F5Networks/f5-azure-arm-templates/blob/master/azure-timezone-list.md)). Example values: UTC, US/Pacific, US/Eastern, Europe/London or Asia/Singapore. |
| dns_server | Yes | Leave the default DNS server (used by BIG-IP)), or replace the default DNS server with the one you want to use. | 
| DO_onboard_URL | Yes | This is the raw github URL for downloading the Declarative Onboarding RPM |
| AS3_URL | Yes | This is the raw github URL for downloading the AS3 RPM. |
| TS_URL | Yes | This is the raw github URL for downloading the Telemetry RPM. |
| CF_URL | Yes | This is the raw github URL for downloading the Cloud-Failover RPM. |
| libs_dir | Yes | This is where all the temporary libs and RPM will be store in BIG-IP. |
| onboard_log | Yes | This is where the onboarding script logs all the events. |
| f5_cloud_failover_label | Yes | This is a tag used for failover. |
| f5_cloud_failover_nic_map | Yes | This is a tag used for failover NIC. |

## Installation Example

To run this Terraform template, perform the following steps:
  1. Clone the repo to your favorite location
  2. Modify terraform.tfvars with the required information
  ```
      # BIG-IP Environment
      uname     = "azureuser"
      upassword = "Default12345!"

      # Azure Environment
      sp_subscription_id = "xxxxx"
      sp_client_id       = "xxxxx"
      sp_client_secret   = "xxxxx"
      sp_tenant_id       = "xxxxx"
      location           = "West US 2"

      # Prefix for objects being created
      prefix = "mylab123"
  ```
  3. Initialize the directory
  ```
      terraform init
  ```
  4. Test the plan and validate errors
  ```
      terraform plan
  ```
  5. Finally, apply and deploy
  ```
      terraform apply
  ```
  6. When done with everything, don't forget to clean up!
  ```
      terraform destroy
  ```

## Configuration Example

The following is an example configuration diagram for this solution deployment. In this scenario, all access to the BIG-IP VE cluster (Active/Standby) is direct to each BIG-IP via the management interface. The IP addresses in this example may be different in your implementation.

![Configuration Example](./AzureFailoverExtensionHighLevel2.gif)


## Documentation

For more information on F5 solutions for Azure, including manual configuration procedures for some deployment scenarios, see the Azure section of [Cloud Failover Doc](https://clouddocs.f5.com/products/extensions/f5-cloud-failover/latest/userguide/azure.html). Also check out the [Azure BIG-IP Lightboard Lessons](https://devcentral.f5.com/s/articles/Lightboard-Lessons-BIG-IP-Deployments-in-Azure-Cloud) on DevCentral.

## Creating virtual servers on the BIG-IP VE

In order to pass traffic from your clients to the servers through the BIG-IP system, you must create a virtual server on the BIG-IP VE. In this template, it creates 2 VIPs, one for public internet facing and one for private internal usage. They are preconfigured as an example and configured the same way as on-prem BIG-IP devices

## Redeploy BIG-IP for replacement or upgrade
This example illustrates how to replace the BIG-IP VE:
  1. Revoke the problematic BIG-IP VE's license (if BYOL)
  2. Run command
```
terraform destroy -target azurerm_virtual_machine.f5vm02
```
  3. Run command
```
terraform apply
```
  4. At this time, you have 2 standalone BIG-IP VEs deployed, but they are not in a cluster yet. Repeat steps 1-3 on the other BIG-IP VE in order to establish Device Trust.


This example illustrates how to upgrade the BIG-IP VEs:
  1. Change the 'bigip_version' variable to the desired release 
  2. Revoke the problematic BIG-IP VE's license
  3. Run command
```
terraform destroy -target azurerm_virtual_machine.f5vm02
```
  4. Run command
```
terraform apply
```
  5. At this time, you have 2 standalone BIG-IP VEs deployed, but they are not in a cluster yet. Repeate steps 2-4 on the other BIG-IP VE in order to establish Device Trust.

## Rerun Application Services AS3 on the BIG-IP VE
- This example illustrates how to run your own custom AS3 (aka application). You can have a catalog of AS3 apps/templates and repeat these steps as many times as desired.
```
terraform taint null_resource.f5vm_AS3
terraform apply -target null_resource.f5vm_AS3 -var "rest_as3_method=POST" -var "rest_vm_as3_file=vm_as3_data.json" 
```

## Rerun Declarative Onboarding on the BIG-IP VE
- This example illustrates how to re-configure the BIG-IP instances with DO. If you need to make changes to the L1-L3 settings if the BIG-IP device or run HA setup again, you can follow these steps.
```
# Steps for f5vm01
terraform taint null_resource.f5vm01_DO
terraform apply -target null_resource.f5vm01_DO -var "rest_do_method=POST" -var "rest_vm01_do_file=vm01_do_data.json" 

# Steps for f5vm02
terraform taint null_resource.f5vm02_DO
terraform apply -target null_resource.f5vm02_DO -var "rest_do_method=POST" -var "rest_vm02_do_file=vm02_do_data.json" 
```

## Rerun Cloud Failover Extension on the BIG-IP VE
- This example illustrates how to re-configure the BIG-IP instances with Cloud Failover Extention. If you need to make changes to the BIG-IP declaration specifying failover objects (NICs, storage, routes, tags), you can follow these steps.
```
# Steps for f5vm01
terraform taint null_resource.f5vm01_CF
terraform apply -target null_resource.f5vm01_CF -var "rest_vm_failover_file=vm_failover_data.json"

# Steps for f5vm02
terraform taint null_resource.f5vm02_CF
terraform apply -target null_resource.f5vm02_CF -var "rest_vm_failover_file=vm_failover_data.json" 
```