# Deploying BIG-IP VEs in Azure - ConfigSync Cluster (Active/Standby): Two NICs

## Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Important Configuration Notes](#important-configuration-notes)
- [Security](#security)
- [Configuration Example](#configuration-example)

## Introduction

This solution uses an Terraform template to launch a two NIC deployment of a cloud-focused BIG-IP VE cluster (Active/Standby) in Microsoft Azure. Traffic flows from an ALB to the BIG-IP VE which then processes the traffic to application servers. This is the standard cloud design where the BIG-IP VE instance is running with a dual interface, where both management and data plane traffic is processed on each one.  

The BIG-IP VEs have the [Local Traffic Manager (LTM)](https://f5.com/products/big-ip/local-traffic-manager-ltm) module enabled to provide advanced traffic management functionality. This means you can also configure the BIG-IP VE to enable F5's L4/L7 security features, access control, and intelligent traffic management.

**Networking Stack Type:** This solution deploys into a new networking stack, which is created along with the solution.

## Prerequisites

- **Important**: When you configure the admin password for the BIG-IP VE in the template, you cannot use the character **#**.  Additionally, there are a number of other special characters that you should avoid using for F5 product user accounts.  See [K2873](https://support.f5.com/csp/article/K2873) for details.
- This template requires a service principal.  See the [Service Principal Setup section](#service-principal-authentication) for details, including required permissions.
- This deployment will be using the Terraform Azurerm provider to build out all the neccessary Azure objects. Therefore, Azure CLI is required. for installation, please follow this [Microsoft link](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt?view=azure-cli-latest)
- If this is the first time to deploy the F5 image, the subscription used in this deployment needs to be enabled to programatically deploy. For more information, please refer to [Configure Programatic Deployment](https://azure.microsoft.com/en-us/blog/working-with-marketplace-images-on-azure-resource-manager/)

## Important configuration notes

- All variables are configured in variables.tf 
- Azure Subscription and Service Principal are configured in provider.tf
- This template would require Declarative Onboarding and AS3 packages for the initial configuration. As part of the onboarding script, it will download the RPMs respectively. So please see the [AS3 documentation](https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/3.5.1/) and [DO documentation](https://clouddocs.f5.com/products/extensions/f5-declarative-onboarding/latest/prereqs.html) for details on how to use AS3 and Declarative Onboarding on your BIG-IP VE(s).
- onboard.tpl is the onboarding script, which is run by commandToExecute, and it will be copy to /var/lib/waagent/CustomData upon bootup. This script is basically responsible for downloading the neccessary DO and AS3 RPM files, installing them, and then executing the onboarding REST calls.
- This template uses PayGo BIGIP image for the deployment (as default). If you would like to use BYOL, then these following steps are needed:
1. In the "variable.tf", specify the BYOL image and licenses regkeys.
2. In the "main.tf", uncomment the "local_sku" lines.
3. Add the following lines to the "cluster.json" file just under the "Common" declaration:
  ```
          "myLicense": {
            "class": "License",
            "licenseType": "regKey",
            "regKey": "${local_sku}"
          },
  ```
- In order to pass traffic from your clients to the servers, after launching the template, you must create virtual server(s) on the BIG-IP VE.  See [Creating a virtual server](#creating-virtual-servers-on-the-big-ip-ve).
- See the **[Configuration Example](#configuration-example)** section for a configuration diagram and description for this solution.

### Template parameters

| Parameter | Required | Description |
| --- | --- | --- |
| prefix | Yes | This value is insert in the beginning of each Azure object, try keeps it alpha-numeric without any special character |
| uname | Yes | User name for the Virtual Machine. |
| upassword | Yes | Password for the Virtual Machine. |
| location | Yes | Location of the deployment. |
| region | Yes | Region of the deployment. |
| cidr | Yes | IP Address range of the Virtual Network. |
| subnet1 | Yes | Subnet IP range of the management network. |
| subnet2 | Yes | Subnet IP range of the external network. |
| subnet3 | No | Subnet IP range of the internal network. |
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
| ntp_server | Yes | Leave the default NTP server the BIG-IP uses, or replace the default NTP server with the one you want to use. |
| timezone | Yes | If you would like to change the time zone the BIG-IP uses, enter the time zone you want to use. This is based on the tz database found in /usr/share/zoneinfo (see the full list [here](https://github.com/F5Networks/f5-azure-arm-templates/blob/master/azure-timezone-list.md)). Example values: UTC, US/Pacific, US/Eastern, Europe/London or Asia/Singapore. |
| dns_server | Yes | Least the default DNS server the BIG-IP uses, or replace the default DNS server with the one you want to use. | 
| DO_onboard_URL | Yes | This is the raw github URL for downloading the Declarative Onboarding RPM |
| AS3_URL | Yes | This is the raw github URL for downloading the AS3 RPM. |
| libs_dir | Yes | This is where all the temporary libs and RPM will be store in BIG-IP. |
| onboard_log | Yes | This is where the onboarding script logs all the events. |

### Programmatic deployments

As an alternative to deploying through the Azure Portal (GUI) each solution provides example scripts to deploy the ARM template.  The example commands can be found below along with the name of the script file, which exists in the current directory.

#### PowerShell Script Example

```powershell
## Example Command: .\Deploy_via_PS.ps1 -numberOfInstances 2 -adminUsername azureuser -authenticationType password -adminPasswordOrKey <value> -dnsLabel <value> -instanceType Standard_DS2_v2 -imageName AllTwoBootLocations -bigIpVersion 13.1.100000 -licenseKey1 <value> -licenseKey2 <value> -vnetAddressPrefix 10.0 -ntpServer 0.pool.ntp.org -timeZone UTC -customImage OPTIONAL -allowUsageAnalytics Yes -resourceGroupName <value>
```

=======

#### Azure CLI (1.0) Script Example

```bash
## Example Command: ./deploy_via_bash.sh --numberOfInstances 2 --adminUsername azureuser --authenticationType password --adminPasswordOrKey <value> --dnsLabel <value> --instanceType Standard_DS2_v2 --imageName AllTwoBootLocations --bigIpVersion 13.1.100000 --licenseKey1 <value> --licenseKey2 <value> --vnetAddressPrefix 10.0 --ntpServer 0.pool.ntp.org --timeZone UTC --customImage OPTIONAL --allowUsageAnalytics Yes --resourceGroupName <value> --azureLoginUser <value> --azureLoginPassword <value>
```

## Configuration Example

The following is an example configuration diagram for this solution deployment. In this scenario, all access to the BIG-IP VE cluster (Active/Standby) is through an ALB. The IP addresses in this example may be different in your implementation.

![Configuration Example](./Secure_Enclave_public_dmz.png)


## Documentation

For more information on F5 solutions for Azure, including manual configuration procedures for some deployment scenarios, see the Azure section of [Public Cloud Docs](http://clouddocs.f5.com/cloud/public/v1/).

## Creating virtual servers on the BIG-IP VE

In order to pass traffic from your clients to the servers through the BIG-IP system, you must create a virtual server on the BIG-IP VE.

In this template, the Azure public IP address is associated with an Azure Load Balancer that forwards traffic to a backend pool that includes the primary (self) IP configurations for *each* BIG-IP network interface.  Because traffic is destined for the self IP addresses of the BIG-IP VEs, you must create a single virtual server with a wildcard destination in Traffic Group **None**.

1. Once your BIG-IP VE has launched, open the BIG-IP VE Configuration utility.
2. On the Main tab, click **Local Traffic > Virtual Servers** and then click the **Create** button.
3. In the **Name** field, give the Virtual Server a unique name.
4. In the **Destination/Mask** field, type the destination address ( for example: 0.0.0.0/0).
5. In the **Service Port** field, type the appropriate port.
6. Configure the rest of the virtual server as appropriate.
7. If you used the Service Discovery iApp template: In the Resources section, from the **Default Pool** list, select the name of the pool created by the iApp.
8. Click the **Finished** button.
9. Repeat as necessary.

When you have completed the virtual server configuration, you must modify the virtual addresses to use Traffic Group None using the following guidance.

1. On the Main tab, click **Local Traffic > Virtual Servers**.
2. On the Menu bar, click the **Virtual Address List** tab.
3. Click the address of one of the virtual servers you just created.
4. From the **Traffic Group** list, select **None**.
5. Click **Update**.
6. Repeat for each virtual server.

