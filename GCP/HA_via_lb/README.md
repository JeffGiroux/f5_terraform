# Deploying BIG-IP VEs in Google - High Availability (Active/Standby): Two NICs

## Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Important Configuration Notes](#important-configuration-notes)
- [BYOL Licensing](#byol-licensing)
- [BIG-IQ License Manager](#big-iq-license-manager)
- [Installation Example](#installation-example)
- [Configuration Example](#configuration-example)
- [Running BIG-IPs in Active/Active](#running-big-ips-in-activeactive)

## Introduction

This solution uses a Terraform template to launch a two NIC deployment of a cloud-focused BIG-IP VE cluster (Active/Standby) in Google GCP. Traffic flows from a Google Load Balancer (GLB) to the BIG-IP VE which then processes the traffic to application servers. This is the standard cloud design where the BIG-IP VE instance is running with a dual interface. Management traffic is processed on NIC 1, and data plane traffic is processed NIC 0.

The BIG-IP VEs have the [Local Traffic Manager (LTM)](https://f5.com/products/big-ip/local-traffic-manager-ltm) module enabled to provide advanced traffic management functionality. In addition, the [Application Security Module (ASM)](https://www.f5.com/pdf/products/big-ip-application-security-manager-overview.pdf) can be enabled to provide F5's L4/L7 security features for web application firewall (WAF) and bot protection.

Terraform is beneficial as it allows composing resources a bit differently to account for dependencies into Immutable/Mutable elements. For example, mutable includes items you would typically frequently change/mutate, such as traditional configs on the BIG-IP. Once the template is deployed, there are certain resources (network infrastructure) that are fixed while others (BIG-IP VMs and configurations) can be changed.

Example...

-> Run once
- Deploy the entire infrastructure with all the neccessary resources, then use Declarative Onboarding (DO) to configure the BIG-IP cluster, Application Services (AS3) to create a sample app proxy, then lastly use Service Discovery to automatically add the DVWA container app to the BIG-IP pool.

-> Run many X
- [Redeploy BIG-IP for Replacement or Upgrade](#Redeploy-BIG-IP-for-replacement-or-upgrade)

**Networking Stack Type:** This solution deploys into an *EXISTING* networking stack. You are required to have existing VPC networks, firewall rules, and proper routing. Refer to the [Prerequisites](#prerequisites). Visit DevCentral to read [Service Discovery in Google Cloud with F5 BIG-IP](https://devcentral.f5.com/s/articles/Service-Discovery-in-Google-Cloud-with-F5-BIG-IP) where I show you my basic VPC setup (networks, subnets) along with firewall rules.

## Version
This template is tested and worked in the following version
Terraform v0.12.26
+ provider.google v3.24
+ provider.local v1.4

## Prerequisites

- ***Important***: When you configure the admin password for the BIG-IP VE in the template, you cannot use the character **#**.  Additionally, there are a number of other special characters that you should avoid using for F5 product user accounts.  See [K2873](https://support.f5.com/csp/article/K2873) for details.
- This template requires one or more service accounts for the BIG-IP instance to perform various tasks:
  - See Google's [Understanding service accounts](https://cloud.google.com/iam/docs/understanding-service-accounts)
  - Google Secret Manager secrets access - requires "Secrets Manager Secret Accessor"
    - Performed by VM instance during onboarding to retrieve passwords and private keys
  - Backend pool service discovery - requires "Compute Viewer"
    - Performed by F5 Application Services AS3
  - Google Cloud Monitoring (aka StackDriver) - requires "Monitoring Editor"
    - Performed by F5 Telemetry Streaming
- This template requires a service account to deploy with the Terraform Google provider and build out all the neccessary Google objects
  - See the [Terraform Google Provider "Adding Credentials"](https://www.terraform.io/docs/providers/google/guides/getting_started.html#adding-credentials) for details. Also, review the [available Google GCP permission scopes](https://cloud.google.com/sdk/gcloud/reference/alpha/compute/instances/set-scopes#--scopes) too.
  - Permissions will depend on the objects you are creating
  - Refer to [IAM-Permissions.md](./IAM-Permissions.md) to see a list of access requested by my Terraform GCP service account in this "BIG-IP Standalone" deployment
  - ***Note***: For lab environments, you can start with "Editor" role. When you are working in other environments, make sure to [practice least privilege](https://cloud.google.com/iam/docs/understanding-service-accounts#granting_minimum).
- ***Shared Service Accounts***: For lab purposes, you can create one service account and use it for everything. Alternatively, you can create a more secure environment with separate service accounts for various functions. Example...
  - Service Account #1 - the svc-acct used for Terraform to deploy cloud objects
  - Service Account #2 - the svc-acct assigned to BIG-IP instance during creation (ex. service discovery, query Pub/Sub, storage)
  - Service Account #3 - the svc-acct used in F5 Telemetry Streaming referenced in [ts.json](./ts.json) (ex. analytics)
- Passwords and secrets are located in [Google Cloud Secret Manager](https://cloud.google.com/secret-manager/docs/quickstart#secretmanager-quickstart-web). Make sure you have an existing Google Cloud "secret" with the data containing the clear text passwords for each relevant item: BIG-IP password, service account credentials, BIG-IQ password, etc.
  - 'usecret' contains the value of the adminstrator password (ex. "Default12345!")
  - 'ksecret' contains the value of the service account private key (ex. "-----BEGIN PRIVATE KEY-----\nMIIEvgIBAmorekeystuffbla123\n-----END PRIVATE KEY-----\n"). Currently used for BIG-IP telemetry streaming to Google Cloud Monitoring (aka StackDriver). If you are not using this feature, you do not need this secret in Secret Manager. 
  - Refer to [Template Parameters](#template-parameters)
- This template deploys into an existing network
  - You must have a VPC for management and a VPC for data traffic (client/server). The management VPC will have one subnet for management traffic. The other VPC will have one subnet for data traffic.
  - Firewall rules are required to pass traffic to the application. These ports will depend on your application and the ports you choose to use.
  - BIG-IP will require tcp/22 and tcp/443 for management access
  - Google ILB health checks are sourced from two internal Google ranges, see [Firewall Rules for Health Checks](https://cloud.google.com/load-balancing/docs/health-checks#fw-rule)
    - Google ILB health checks to backend BIG-IP instances require tcp/40000 (in this example)
  - If you require a new network first, see the [Infrastructure Only folder](../Infrastructure-only) to get started.
  

## Important Configuration Notes

- Variables are configured in variables.tf
- Sensitive variables like Google SSH keys are configured in terraform.tfvars
  - ***Note***: Other items like BIG-IP password are stored in Google Cloud Secret Manager. Refer to the [Prerequisites](#prerequisites).
  - The BIG-IP instance will query Google Metadata API to retrieve the service account's token for authentication.
  - The BIG-IP instance will then use the secret name and the service account's token to query Google Metadata API and dynamically retrieve the password for device onboarding.
- This template uses Declarative Onboarding (DO) and Application Services 3 (AS3) for the initial configuration. As part of the onboarding script, it will download the RPMs automatically. See the [AS3 documentation](http://f5.com/AS3Docs) and [DO documentation](http://f5.com/DODocs) for details on how to use AS3 and Declarative Onboarding on your BIG-IP VE(s). The [Telemetry Streaming](http://f5.com/TSDocs) extension is also downloaded and can be configured to point to Google Cloud Monitoring (old name StackDriver).
- Files
  - bigip.tf - resources for BIG-IP, NICs, public IPs
  - main.tf - resources for provider, versions
  - onboard.tpl - onboarding script which is run by startup-script (user data). It will be copied to **startup-script=*path-to-file*** upon bootup. This script is responsible for downloading the neccessary F5 Automation Toolchain RPM files, installing them, and then executing the onboarding REST calls.
  - do.json - contains the L1-L3 BIG-IP configurations used by DO for items like VLANs, IPs, and routes.
  - as3.json - contains the L4-L7 BIG-IP configurations used by AS3 for items like pool members, virtual server listeners, security policies, and more.
  - ts.json - contains the BIG-IP configurations used by TS for items like telemetry streaming, CPU, memory, application statistics, and more.

## BYOL Licensing
This template uses PayGo BIG-IP image for the deployment (as default). If you would like to use BYOL licenses, then these following steps are needed:
1. Find available images/versions with "byol" in the name using Google gcloud:
  ```
          gcloud compute images list --project=f5-7626-networks-public | grep f5

          # example output...

          --snippet--
          f5-bigip-13-1-3-2-0-0-4-payg-best-1gbps-20191105210022
          f5-bigip-13-1-3-2-0-0-4-payg-best-200mbps-20191105210022
          f5-bigip-13-1-3-2-0-0-4-byol-all-modules-2slot-20191105200157
          ...and some more
          f5-bigip-14-1-2-3-0-0-5-byol-ltm-1boot-loc-191218142225
          f5-bigip-14-1-2-3-0-0-5-payg-best-1gbps-191218142340
          f5-bigip-15-1-0-2-0-0-9-payg-best-25mbps-200321032524
          ...and more...
  ```
2. In the "variables.tf", modify *image_name* with the image name from gcloud CLI results
  ```
          # BIGIP Image
          variable image_name { default = "projects/f5-7626-networks-public/global/images/f5-bigip-14-1-2-3-0-0-5-byol-ltm-2boot-loc-191218142235" }
  ```
3. In the "variables.tf", modify *license1* with a valid regkey
  ```
          # BIGIP Setup
          variable license1 { default = "" }
  ```
4. In the "do.json", add the "myLicense" block under the "Common" declaration ([full declaration example here](https://clouddocs.f5.com/products/extensions/f5-declarative-onboarding/latest/bigip-examples.html#standalone-declaration))
  ```
        "myLicense": {
            "class": "License",
            "licenseType": "regKey",
            "regKey": "${regKey}"
        },
  ```

## BIG-IQ License Manager
This template uses PayGo BIG-IP image for the deployment (as default). If you would like to use BYOL/ELA/Subscription licenses from [BIG-IQ License Manager (LM)](https://devcentral.f5.com/s/articles/managing-big-ip-licensing-with-big-iq-31944), then these following steps are needed:
1. Find BYOL image. Reference [BYOL Licensing](#byol-licensing) step #1.
2. Replace BIG-IP *image_name* in "variables.tf". Reference [BYOL Licensing](#byol-licensing) step #2.
3. In the "variables.tf", modify the BIG-IQ license section to match your environment
4. In the "do.json", add the "myLicense" block under the "Common" declaration ([full declaration example here](https://clouddocs.f5.com/products/extensions/f5-declarative-onboarding/latest/bigiq-examples.html#licensing-with-big-iq-regkey-pool-route-to-big-ip))
  ```
        "myLicense": {
            "class": "License",
            "licenseType": "${bigIqLicenseType}",
            "bigIqHost": "${bigIqHost}",
            "bigIqUsername": "${bigIqUsername}",
            "bigIqPassword": "$${bigIqPassword}",
            "licensePool": "${bigIqLicensePool}",
            "skuKeyword1": "${bigIqSkuKeyword1}",
            "skuKeyword2": "${bigIqSkuKeyword2}",
            "unitOfMeasure": "${bigIqUnitOfMeasure}",
            "reachable": false,
            "hypervisor": "${bigIqHypervisor}",
            "overwrite": true
        },
  ```
  ***Note***: The [onboard.tpl](./onboard.tpl) startup script will use the same 'usecret' payload value (aka password) for BIG-IP password AND the BIG-IQ password. In the onboard.tpl file, this happens in the 'passwd' variable. You can use a separate password for BIG-IQ by creating a new Google Secret Manager secret for the BIG-IQ password, then add a new variable for the secret in [variables.tf](./variables.tf), modify [bigip.tf](./bigip.tf) to include the secret in the local templatefile section similar to 'usecret', then update [onboard.tpl](./onboard.tpl) to query Secret Manager for the BIG-IQ secret name. Reference code example *usecret='${usecret}'*.

## Template Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| prefix | Yes | This value is inserted at the beginning of each Google object (alpha-numeric, no special character) |
| uname | Yes | User name for the Virtual Machine |
| usecret | Yes | Used during onboarding to query the Google Cloud Secret Manager API and retrieve the admin password (use the secret name, not the secret value/password) |
| gceSshPubKey | Yes | SSH public key for admin authentation |
| adminSrcAddr | Yes | Trusted source network for admin access |
| gcp_project_id | Yes | GCP Project ID for provider |
| gcp_zone | Yes | GCP Zone for provider |
| gcp_region | Yes | GCP Region for provider |
| svc_acct | Yes | Service Account for VM instance |
| privateKeyId | No | ID of private key for the service account used in Telemetry Streaming to Google Cloud Monitoring |
| ksecret | No | Used during onboarding to query the Google Cloud Secret Manager API and retrieve the service account privateKey (use the secret name, not the secret value/privateKey) |
| extVpc | Yes | External VPC network |
| mgmtVpc | Yes | Management VPC network |
| extSubnet | Yes | External subnet |
| mgmtSubnet | Yes | Management subnet |
| bigipMachineType | Yes | Google machine type to be used for the BIG-IP VE |
| image_name | Yes | F5 SKU (image) to deploy. Note: The disk size of the VM will be determined based on the option you select.  **Important**: If intending to provision multiple modules, ensure the appropriate value is selected, such as ****AllTwoBootLocations or AllOneBootLocation****. |
| license1 | No | The license token for the F5 BIG-IP VE (BYOL) |
| license2 | No | The license token for the F5 BIG-IP VE (BYOL) |
| host1_name | Yes | Hostname for the 1st BIG-IP |
| host2_name | Yes | Hostname for the 2nd BIG-IP |
| ntp_server | Yes | Leave the default NTP server the BIG-IP uses, or replace the default NTP server with the one you want to use |
| timezone | Yes | If you would like to change the time zone the BIG-IP uses, enter the time zone you want to use. This is based on the tz database found in /usr/share/zoneinfo (see the full list [here](https://cloud.google.com/dataprep/docs/html/Supported-Time-Zone-Values_66194188)). Example values: UTC, US/Pacific, US/Eastern, Europe/London or Asia/Singapore. |
| dns_server | Yes | Leave the default DNS server the BIG-IP uses, or replace the default DNS server with the one you want to use | 
| dns_suffix | Yes | DNS suffix for your domain | 
| DO_URL | Yes | This is the raw github URL for downloading the Declarative Onboarding RPM |
| AS3_URL | Yes | This is the raw github URL for downloading the AS3 RPM |
| TS_URL | Yes | This is the raw github URL for downloading the Telemetry RPM |
| onboard_log | Yes | This is where the onboarding script logs all the events |
| bigIqHost | No | This is the BIG-IQ License Manager host name or IP address |
| bigIqUsername | No | BIG-IQ user name |
| bigIqLicenseType | No | BIG-IQ license type |
| bigIqLicensePool | No | BIG-IQ license pool name |
| bigIqSkuKeyword1 | No | BIG-IQ license SKU keyword 1 |
| bigIqSkuKeyword2 | No | BIG-IQ license SKU keyword 1 |
| bigIqUnitOfMeasure | No | BIG-IQ license unit of measure |
| bigIqHypervisor | No | BIG-IQ hypervisor |

## Installation Example

To run this Terraform template, perform the following steps:
  1. Clone the repo to your favorite location
  2. Modify terraform.tfvars with the required information
  ```
      # BIG-IP Environment
      uname        = "admin"
      usecret      = "my-secret"
      gceSshPubKey = "ssh-rsa xxxxx
      prefix       = "mydemo123"
      adminSrcAddr = "0.0.0.0/0"
      mgmtVpc      = "xxxxx-net-mgmt"
      extVpc       = "xxxxx-net-ext"
      mgmtSubnet   = "xxxxx-subnet-mgmt"
      extSubnet    = "xxxxx-subnet-ext"
      dns_suffix   = "example.com"

      # BIG-IQ Environment
      bigIqUsername = "admin"

      # Google Environment
      gcp_project_id = "xxxxx"
      gcp_region     = "us-west1"
      gcp_zone       = "us-west1-b"
      svc_acct       = "xxxxx@xxxxx.iam.gserviceaccount.com"
      privateKeyId   = "abcdcba123321"
      ksecret        = "svc-acct-secret"
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

![Configuration Example](./images/gcp-bigip-ha-via-lb.png)

## Documentation

For more information on F5 solutions for Google, including manual configuration procedures for some deployment scenarios, see the Google GCP section of [F5 CloudDocs](https://clouddocs.f5.com/cloud/public/v1/google_index.html). Also check out the [Using Cloud Templates for BIG-IP in Google](https://devcentral.f5.com/s/articles/Using-Cloud-Templates-to-Change-BIG-IP-Versions-Google) on DevCentral. This particular HA example is based on the [BIG-IP Cluster "HA via LB" F5 GDM Cloud Template on GitHub](https://github.com/F5Networks/f5-google-gdm-templates/tree/master/supported/failover/same-net/via-lb/3nic/existing-stack).

## Creating Virtual Servers on the BIG-IP VE

In order to pass traffic from your clients to the servers through the BIG-IP system, you must create a virtual server on the BIG-IP VE. In this template, the AS3 declaration creates 1 VIP listening on 0.0.0.0/0, port 8443. It is preconfigured as an example.

In this template, the Google public IP address is associated with the Google Load Balancer (GLB) which has both BIG-IP devices as backends. The address is created with a [Google Forwarding Rule](https://cloud.google.com/load-balancing/docs/forwarding-rule-concepts), and this IP address will be the same IP you see as a virtual server on the BIG-IP.

***Note:*** These next steps illustrate the manual way in the GUI to create a virtual server
1. Open the BIG-IP VE Configuration utility
2. Click **Local Traffic > Virtual Servers**
3. Click the **Create** button
4. Type a name in the **Name** field
4. Type an address (ex. 0.0.0.0/0) in the **Destination/Mask** field
5. Type a port (ex. 443) in the **Service Port**
6. Configure the rest of the virtual server as appropriate
7. Select a pool name from the **Default Pool** list
8. Click the **Finished** button
9. Repeat as necessary for other applications by using different ports (ex. 0.0.0.0/0:9443, 0.0.0.0/0:8444)

## Running BIG-IPs in Active/Active
You can make this deployment of BIG-IP devices run Active/Active too. When you have completed the virtual server configuration, you must modify the virtual addresses to use Traffic Group "None" using the following guidance. This allows both BIG-IP devices to respond to GLB health probes and therefore Active/Active is achieved. 

1. On the Main tab, click **Local Traffic > Virtual Servers**
2. On the Menu bar, click the **Virtual Address List** tab
3. Click the address of the virtual server you just created like 0.0.0.0/0
4. From the **Traffic Group** list, select **None**
5. Click **Update**
6. Repeat for each virtual server address

## Redeploy BIG-IP for Replacement or Upgrade
This example illustrates how to replace or upgrade the BIG-IP VE.
  1. Change the *image_name* variable to the desired release 
  2. Revoke the problematic BIG-IP VE's license (if BYOL)
  3. Run command
```
terraform taint google_compute_instance.f5vm01
terraform taint google_compute_instance.f5vm02
```
  3. Run command
```
terraform apply
```
