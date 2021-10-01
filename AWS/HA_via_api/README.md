# Deploying BIG-IP VEs in AWS Across-Net - High Availability (Active/Standby): 3-NIC

## To Do
- Community support only. Not F5 supported.
- Move to AWS secret manager. Currently passwords are stored in clear text in the runtime init YAML file local to the BIG-IP box.
- TS still not used and not installed
- Route table created for CFE demonstration but not associated with subnets

## Issues
- Find an issue? Fork, clone, create branch, fix and PR. I'll review and merge into the main branch. Or submit a GitHub issue with all necessary details and logs.


## Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Important Configuration Notes](#important-configuration-notes)
- [BYOL Licensing](#byol-licensing)
- [BIG-IQ License Manager](#big-iq-license-manager)
- [Installation Example](#installation-example)
- [Configuration Example](#configuration-example)
- [Troubleshooting](#troubleshooting)

## Introduction

This solution uses a Terraform template to launch a 3-NIC deployment of a cloud-focused BIG-IP VE cluster (Active/Standby) in AWS across two AWS Availability Zones. Traffic flows to the BIG-IP VE which then processes the traffic to application servers. The BIG-IP VE instance is running with multiple interfaces: management, external, internal. NIC1 is associated with the external network while NIC2 is associated with the internal network.

The BIG-IP VEs have the [Local Traffic Manager (LTM)](https://f5.com/products/big-ip/local-traffic-manager-ltm) module enabled to provide advanced traffic management functionality. In addition, the [Application Security Module (ASM)](https://www.f5.com/pdf/products/big-ip-application-security-manager-overview.pdf) can be enabled to provide F5's L4/L7 security features for web application firewall (WAF) and bot protection.

The BIG-IP's configuration, now defined in a single convenient YAML or JSON [F5 BIG-IP Runtime Init](https://github.com/F5Networks/f5-bigip-runtime-init) configuration file, leverages [F5 Automation Tool Chain](https://www.f5.com/pdf/products/automation-toolchain-overview.pdf) declarations which are easier to author, validate and maintain as code. For instance, if you need to change the configuration on the BIG-IPs in the deployment, you update the instance model by passing a new config file (which references the updated Automation Toolchain declarations) via template's runtimeConfig input parameter. New instances will be deployed with the updated configurations.


## Prerequisites

- ***Important***: When you configure the admin password for the BIG-IP VE in the template, you cannot use the character **#**.  Additionally, there are a number of other special characters that you should avoid using for F5 product user accounts.  See [K2873](https://support.f5.com/csp/article/K2873) for details.
- This template requires one or more service accounts for the BIG-IP instance to perform various tasks:
  - AWS Secrets Manager - requires (TBD...not tested yet)
    - Performed by VM instance during onboarding to retrieve passwords and private keys
  - Backend pool service discovery - requires various roles
    - Performed by F5 Application Services AS3
    - See [CFE Docs for AWS - Create IAM Role](https://clouddocs.f5.com/products/extensions/f5-cloud-failover/latest/userguide/aws.html#create-and-assign-an-iam-role)
- The HA BIG-IP VMs use AWS IAM role for the failover
- These BIG-IP VMs are deployed across different Availability Zones
- This template requires programmatic API credentials to deploy the Terraform AWS provider and build out all the neccessary AWS objects
  - See the [Terraform "AWS Provider"](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication) for details
  - You will require at minimum `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
  - ***Note***: Make sure to [practice least privilege](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- This templates deploys into an *EXISTING* networking stack. You are required to have an existing VPC network, subnets, and security groups.
  - A NAT gateway or public IP is also required for outbound Internet traffic
  - If you require a new network first, see the [Infrastructure Only folder](../Infrastructure-only) to get started


## Important Configuration Notes

- Variables are configured in variables.tf
- Sensitive variables like AWS SSH keys are configured in terraform.tfvars or AWS Secrets Manager
  - ***Note***: Passwords and secrets will be moved to AWS Secrets Manager in the future
  - (TBD) The BIG-IP instance will query AWS Metadata API to retrieve the service account's token for authentication
  - (TBD) The BIG-IP instance will then use the secret name and the service account's token to query AWS Metadata API and dynamically retrieve the password for device onboarding
- This template uses Declarative Onboarding (DO), Application Services 3 (AS3), and Cloud Failover Extension packages for the initial configuration. As part of the onboarding script, it will download the RPMs automatically. See the [AS3 documentation](http://f5.com/AS3Docs) and [DO documentation](http://f5.com/DODocs) for details on how to use AS3 and Declarative Onboarding on your BIG-IP VE(s). The [Telemetry Streaming](http://f5.com/TSDocs) extension is also downloaded and can be configured to point to AWS Cloud Watch. The [Cloud Failover Extension](http://f5.com/CFEDocs) documentation is also available.

- Files
  - bigip.tf - resources for BIG-IP, NICs, public IPs
  - main.tf - resources for provider, versions, storage buckets
  - iam.tf - resources for IAM roles
  - bigip.tf - resources for BIG-IP, security groups, route table
  - f5_onboard.tmpl - onboarding script which is run by user-data. This script is responsible for downloading the neccessary F5 Automation Toolchain RPM files, installing them, and then executing the onboarding REST calls via the [BIG-IP Runtime Init tool](https://github.com/F5Networks/f5-bigip-runtime-init).

## BYOL Licensing
This template uses PayGo BIG-IP image for the deployment (as default). If you would like to use BYOL licenses, then these following steps are needed:
1. Find available images/versions with "byol" in SKU name using AWS CLI:
  ```
          aws ec2 describe-images \
            --region us-west-2 \
            --filters "Name=name,Values=*BIGIP*15.1.2.1*BYOL*" \
            --query 'Images[*].[ImageId,Name]'

          #Output similar to this...
          [
              "ami-0704e9e0efd3a9950",
              "F5 BIGIP-15.1.2.1-0.0.10 BYOL-LTM 2Boot Loc-210115154531-6d69f6a1-37da-4a16-846c-aeb7cc0402aa-ami-03ebd220106268e94.4"
          ],
  ```
2. In the "variables.tf", modify *f5_ami_search_name* with a value from previous output
  ```
          # BIGIP Image
          variable "f5_ami_search_name" { default = "F5 BIGIP-15.1.2.1* BYOL-All* 2Boot*" }
  ```
3. In the "variables.tf", modify *license1* and *license2* with valid regkeys
  ```
          # BIGIP Setup
          variable license1 { default = "" }
          variable license2 { default = "" }
  ```
4. In the "f5_onboard.tmpl", add the "myLicense" block under the "Common" declaration
  ```
          myLicense:
            class: License
            licenseType: regKey
            regKey: '${regKey}'
  ```

## BIG-IQ License Manager
This template uses PayGo BIG-IP image for the deployment (as default). If you would like to use BYOL/ELA/Subscription licenses from [BIG-IQ License Manager (LM)](https://devcentral.f5.com/s/articles/managing-big-ip-licensing-with-big-iq-31944), then these following steps are needed:
1. In the "variables.tf", modify *f5_ami_search_name* value with a BYOL filter in the name. Example below...
  ```
          # BIGIP Image
          variable "f5_ami_search_name" { default = "F5 BIGIP-15.1.2.1* BYOL-All* 2Boot*" }
  ```
2. In the "variables.tf", modify the BIG-IQ license section to match your environment
3. In the "f5_onboard.tmpl", add the "myLicense" block under the "Common" declaration ([example here](https://github.com/F5Networks/f5-aws-cloudformation-v2/blob/main/examples/autoscale/bigip-configurations/runtime-init-conf-bigiq.yaml))
  ```
          myLicense:
            class: License
            licenseType: ${bigIqLicenseType}
            bigIqHost: ${bigIqHost}
            bigIqUsername: ${bigIqUsername}
            bigIqPassword: ${bigIqPassword}
            licensePool: ${bigIqLicensePool}
            skuKeyword1: ${bigIqSkuKeyword1}
            skuKeyword2: ${bigIqSkuKeyword2}
            unitOfMeasure: ${bigIqUnitOfMeasure}
            reachable: false
            hypervisor: ${bigIqHypervisor}
            overwrite: true
  ```

<!-- markdownlint-disable no-inline-html -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 0.14 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 3.60.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eip.vip-pip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eip.vm01-ext-pip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eip.vm01-mgmt-pip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eip.vm02-ext-pip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eip.vm02-mgmt-pip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_iam_instance_profile.bigip_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.bigip_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_instance.f5vm01](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_instance.f5vm02](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_key_pair.bigip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_network_interface.vm01-ext-nic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_network_interface.vm01-int-nic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_network_interface.vm01-mgmt-nic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_network_interface.vm02-ext-nic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_network_interface.vm02-int-nic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_network_interface.vm02-mgmt-nic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_interface) | resource |
| [aws_route_table.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_s3_bucket.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [random_id.buildSuffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [aws_ami.f5_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_iam_policy_document.bigip_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.bigip_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ssh_key"></a> [ssh\_key](#input\_ssh\_key) | public key used for authentication in ssh-rsa format | `string` | n/a | yes |
| <a name="input_AS3_URL"></a> [AS3\_URL](#input\_AS3\_URL) | URL to download the BIG-IP Application Service Extension 3 (AS3) module | `string` | `"https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.30.0/f5-appsvcs-3.30.0-5.noarch.rpm"` | no |
| <a name="input_CFE_URL"></a> [CFE\_URL](#input\_CFE\_URL) | URL to download the BIG-IP Cloud Failover Extension module | `string` | `"https://github.com/F5Networks/f5-cloud-failover-extension/releases/download/v1.9.0/f5-cloud-failover-1.9.0-0.noarch.rpm"` | no |
| <a name="input_DO_URL"></a> [DO\_URL](#input\_DO\_URL) | URL to download the BIG-IP Declarative Onboarding module | `string` | `"https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.23.0/f5-declarative-onboarding-1.23.0-4.noarch.rpm"` | no |
| <a name="input_FAST_URL"></a> [FAST\_URL](#input\_FAST\_URL) | URL to download the BIG-IP FAST module | `string` | `"https://github.com/F5Networks/f5-appsvcs-templates/releases/download/v1.11.0/f5-appsvcs-templates-1.11.0-1.noarch.rpm"` | no |
| <a name="input_INIT_URL"></a> [INIT\_URL](#input\_INIT\_URL) | URL to download the BIG-IP runtime init | `string` | `"https://cdn.f5.com/product/cloudsolutions/f5-bigip-runtime-init/v1.2.1/dist/f5-bigip-runtime-init-1.2.1-1.gz.run"` | no |
| <a name="input_TS_URL"></a> [TS\_URL](#input\_TS\_URL) | URL to download the BIG-IP Telemetry Streaming module | `string` | `"https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.22.0/f5-telemetry-1.22.0-1.noarch.rpm"` | no |
| <a name="input_allowedIps"></a> [allowedIps](#input\_allowedIps) | Trusted source network for admin access | `list(any)` | <pre>[<br>  "0.0.0.0/0"<br>]</pre> | no |
| <a name="input_awsRegion"></a> [awsRegion](#input\_awsRegion) | aws region | `string` | `"us-west-2"` | no |
| <a name="input_bigIqHost"></a> [bigIqHost](#input\_bigIqHost) | This is the BIG-IQ License Manager host name or IP address | `string` | `""` | no |
| <a name="input_bigIqHypervisor"></a> [bigIqHypervisor](#input\_bigIqHypervisor) | BIG-IQ hypervisor | `string` | `"aws"` | no |
| <a name="input_bigIqLicensePool"></a> [bigIqLicensePool](#input\_bigIqLicensePool) | BIG-IQ license pool name | `string` | `""` | no |
| <a name="input_bigIqLicenseType"></a> [bigIqLicenseType](#input\_bigIqLicenseType) | BIG-IQ license type | `string` | `"licensePool"` | no |
| <a name="input_bigIqPassword"></a> [bigIqPassword](#input\_bigIqPassword) | Admin Password for BIG-IQ | `string` | `"Default12345!"` | no |
| <a name="input_bigIqSkuKeyword1"></a> [bigIqSkuKeyword1](#input\_bigIqSkuKeyword1) | BIG-IQ license SKU keyword 1 | `string` | `"key1"` | no |
| <a name="input_bigIqSkuKeyword2"></a> [bigIqSkuKeyword2](#input\_bigIqSkuKeyword2) | BIG-IQ license SKU keyword 2 | `string` | `"key2"` | no |
| <a name="input_bigIqUnitOfMeasure"></a> [bigIqUnitOfMeasure](#input\_bigIqUnitOfMeasure) | BIG-IQ license unit of measure | `string` | `"hourly"` | no |
| <a name="input_bigIqUsername"></a> [bigIqUsername](#input\_bigIqUsername) | Admin name for BIG-IQ | `string` | `"azureuser"` | no |
| <a name="input_cfe_managed_route"></a> [cfe\_managed\_route](#input\_cfe\_managed\_route) | A route can used for testing managed-route failover. Enter address prefix like x.x.x.x/x | `string` | `"0.0.0.0/0"` | no |
| <a name="input_dns_server"></a> [dns\_server](#input\_dns\_server) | Leave the default DNS server the BIG-IP uses, or replace the default DNS server with the one you want to use | `string` | `"8.8.8.8"` | no |
| <a name="input_ec2_instance_type"></a> [ec2\_instance\_type](#input\_ec2\_instance\_type) | AWS instance type for the BIG-IP | `string` | `"m5.xlarge"` | no |
| <a name="input_extNsg"></a> [extNsg](#input\_extNsg) | ID of external security group | `string` | `null` | no |
| <a name="input_extSubnetAz1"></a> [extSubnetAz1](#input\_extSubnetAz1) | ID of External subnet AZ1 | `string` | `null` | no |
| <a name="input_extSubnetAz2"></a> [extSubnetAz2](#input\_extSubnetAz2) | ID of External subnet AZ2 | `string` | `null` | no |
| <a name="input_f5_ami_search_name"></a> [f5\_ami\_search\_name](#input\_f5\_ami\_search\_name) | AWS AMI search filter to find correct BIG-IP VE for region | `string` | `"F5 BIGIP-15.1.2.1* PAYG-Best 200Mbps*"` | no |
| <a name="input_f5_password"></a> [f5\_password](#input\_f5\_password) | BIG-IP Password | `string` | `"Default12345!"` | no |
| <a name="input_f5_username"></a> [f5\_username](#input\_f5\_username) | User name for the BIG-IP (Note: currenlty not used. Defaults to 'admin' based on AMI | `string` | `"admin"` | no |
| <a name="input_intNsg"></a> [intNsg](#input\_intNsg) | ID of internal security group | `string` | `null` | no |
| <a name="input_intSubnetAz1"></a> [intSubnetAz1](#input\_intSubnetAz1) | ID of Internal subnet AZ1 | `string` | `null` | no |
| <a name="input_intSubnetAz2"></a> [intSubnetAz2](#input\_intSubnetAz2) | ID of Internal subnet AZ2 | `string` | `null` | no |
| <a name="input_libs_dir"></a> [libs\_dir](#input\_libs\_dir) | Directory on the BIG-IP to download the A&O Toolchain into | `string` | `"/config/cloud/aws/node_modules"` | no |
| <a name="input_license1"></a> [license1](#input\_license1) | The license token for the 1st F5 BIG-IP VE (BYOL) | `string` | `""` | no |
| <a name="input_license2"></a> [license2](#input\_license2) | The license token for the 2nd F5 BIG-IP VE (BYOL) | `string` | `""` | no |
| <a name="input_mgmtNsg"></a> [mgmtNsg](#input\_mgmtNsg) | ID of management security group | `string` | `null` | no |
| <a name="input_mgmtSubnetAz1"></a> [mgmtSubnetAz1](#input\_mgmtSubnetAz1) | ID of Management subnet AZ1 | `string` | `null` | no |
| <a name="input_mgmtSubnetAz2"></a> [mgmtSubnetAz2](#input\_mgmtSubnetAz2) | ID of Management subnet AZ2 | `string` | `null` | no |
| <a name="input_ntp_server"></a> [ntp\_server](#input\_ntp\_server) | Leave the default NTP server the BIG-IP uses, or replace the default NTP server with the one you want to use | `string` | `"0.us.pool.ntp.org"` | no |
| <a name="input_onboard_log"></a> [onboard\_log](#input\_onboard\_log) | Directory on the BIG-IP to store the cloud-init logs | `string` | `"/var/log/cloud/startup-script.log"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | This is a tag used for object creation. Example is last name. | `string` | `null` | no |
| <a name="input_projectPrefix"></a> [projectPrefix](#input\_projectPrefix) | prefix for resources | `string` | `"myDemo"` | no |
| <a name="input_resourceOwner"></a> [resourceOwner](#input\_resourceOwner) | owner of the deployment, for tagging purposes | `string` | `"myName"` | no |
| <a name="input_timezone"></a> [timezone](#input\_timezone) | If you would like to change the time zone the BIG-IP uses, enter the time zone you want to use. This is based on the tz database found in /usr/share/zoneinfo (see the full list [here](https://github.com/F5Networks/f5-azure-arm-templates/blob/master/azure-timezone-list.md)). Example values: UTC, US/Pacific, US/Eastern, Europe/London or Asia/Singapore. | `string` | `"UTC"` | no |
| <a name="input_vpcId"></a> [vpcId](#input\_vpcId) | The AWS network VPC ID | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_f5vm01_ext_private_ip"></a> [f5vm01\_ext\_private\_ip](#output\_f5vm01\_ext\_private\_ip) | f5vm01 external primary IP address (self IP) |
| <a name="output_f5vm01_ext_secondary_ip"></a> [f5vm01\_ext\_secondary\_ip](#output\_f5vm01\_ext\_secondary\_ip) | f5vm01 external secondary IP address (VIP) |
| <a name="output_f5vm01_int_private_ip"></a> [f5vm01\_int\_private\_ip](#output\_f5vm01\_int\_private\_ip) | f5vm01 internal primary IP address |
| <a name="output_f5vm01_mgmt_private_ip"></a> [f5vm01\_mgmt\_private\_ip](#output\_f5vm01\_mgmt\_private\_ip) | f5vm01 management private IP address |
| <a name="output_f5vm01_mgmt_public_ip"></a> [f5vm01\_mgmt\_public\_ip](#output\_f5vm01\_mgmt\_public\_ip) | f5vm01 management public IP address |
| <a name="output_f5vm02_ext_private_ip"></a> [f5vm02\_ext\_private\_ip](#output\_f5vm02\_ext\_private\_ip) | f5vm02 external primary IP address (self IP) |
| <a name="output_f5vm02_ext_secondary_ip"></a> [f5vm02\_ext\_secondary\_ip](#output\_f5vm02\_ext\_secondary\_ip) | f5vm02 external secondary IP address (VIP) |
| <a name="output_f5vm02_int_private_ip"></a> [f5vm02\_int\_private\_ip](#output\_f5vm02\_int\_private\_ip) | f5vm02 internal primary IP address |
| <a name="output_f5vm02_mgmt_private_ip"></a> [f5vm02\_mgmt\_private\_ip](#output\_f5vm02\_mgmt\_private\_ip) | f5vm02 management private IP address |
| <a name="output_f5vm02_mgmt_public_ip"></a> [f5vm02\_mgmt\_public\_ip](#output\_f5vm02\_mgmt\_public\_ip) | f5vm02 management public IP address |
| <a name="output_public_vip_pip"></a> [public\_vip\_pip](#output\_public\_vip\_pip) | Public IP for the BIG-IP listener (VIP) |
| <a name="output_route_table"></a> [route\_table](#output\_route\_table) | Route table ID |
| <a name="output_storage_bucket"></a> [storage\_bucket](#output\_storage\_bucket) | AWS storage bucket ARN |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- markdownlint-enable no-inline-html -->

## Installation Example

To run this Terraform template, perform the following steps:
  1. Clone the repo to your favorite location
  2. Modify terraform.tfvars with the required information
  ```
      # BIG-IP Environment
      allowedIps    = ["0.0.0.0/0"]
      vpcId         = "vpc-1234"
      mgmtSubnetAz1 = "subnet-1111"
      mgmtSubnetAz2 = "subnet-2222"
      extSubnetAz1  = "subnet-3333"
      extSubnetAz2  = "subnet-4444"
      intSubnetAz1  = "subnet-5555"
      intSubnetAz2  = "subnet-6666"
      mgmtNsg       = "sg-1111"
      extNsg        = "sg-3333"
      intNsg        = "sg-5555"
      ssh_key       = "ssh-rsa AAABC123....."
      f5_username   = "admin"
      f5_password   = "Default12345!"

      # AWS Environment
      awsRegion     = "us-west-2"
      projectPrefix = "mydemo"
      resourceOwner = "myname"
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

![Configuration Example](./images/failover-across-az-multiple-vips.gif)

## Documentation

For more information on F5 solutions for AWS, including manual configuration procedures for some deployment scenarios, see the AWS section of [F5 CloudDocs](https://clouddocs.f5.com/cloud/public/v1/aws_index.html). Also check out the [Using Cloud Templates for BIG-IP in AWS](https://devcentral.f5.com/s/articles/Using-Cloud-Templates-to-Change-BIG-IP-Versions-AWS) on DevCentral.

## Creating Virtual Servers on the BIG-IP VE

In order to pass traffic from your clients to the servers through the BIG-IP system, you must create a virtual server on each BIG-IP VE. This demo creates a demo virtual server using AS3. See [AS3 in AWS Failover Across-Net](https://clouddocs.f5.com/products/extensions/f5-cloud-failover/latest/userguide/aws.html#example-virtual-service-declaration) for an example declaration using AS3.

***Note:*** These next steps illustrate the manual way in the GUI to create a virtual server
1. Open the BIG-IP VE Configuration utility
2. Click **Local Traffic > Virtual Servers**
3. Click the **Create** button
4. Type a name in the **Name** field
4. Type an address (ex. x.x.x.x/x) in the **Destination/Mask** field
5. Type a port (ex. 443) in the **Service Port**
6. Configure the rest of the virtual server as appropriate
7. Select a pool name from the **Default Pool** list
8. Click the **Finished** button
9. Repeat as necessary for other applications

## Troubleshooting

### F5 Automation Toolchain Components
F5 BIG-IP Runtime Init uses the F5 Automation Toolchain for configuration of BIG-IP instances.  Any errors thrown from these components will be surfaced in the bigIpRuntimeInit.log (or a custom log location as specified below).

Help with troubleshooting individual Automation Toolchain components can be found at F5's [Public Cloud Docs](http://clouddocs.f5.com/cloud/public/v1/):
- DO: https://clouddocs.f5.com/products/extensions/f5-declarative-onboarding/latest/troubleshooting.html
- AS3: https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/userguide/troubleshooting.html
- FAST: https://clouddocs.f5.com/products/extensions/f5-appsvcs-templates/latest/userguide/troubleshooting.html
- TS: https://clouddocs.f5.com/products/extensions/f5-telemetry-streaming/latest/userguide/troubleshooting.html
- CFE: https://clouddocs.f5.com/products/extensions/f5-cloud-failover/latest/userguide/troubleshooting.html
