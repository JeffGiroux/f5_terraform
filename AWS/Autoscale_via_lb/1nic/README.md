# Deploying BIG-IP VEs in AWS - Auto Scale (Active/Active): 2-NIC

## To Do
- testing
- update readme
- move to AWS secret manager
- create AWS NLB
- fix AS3 on BIG-IP, otherwise NLB health checks fail


## Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Important Configuration Notes](#important-configuration-notes)
- [BIG-IQ License Manager](#big-iq-license-manager)
- [Installation Example](#installation-example)
- [Configuration Example](#configuration-example)

## Introduction

This solution uses a Terraform template to launch a 1-NIC deployment of a cloud-focused BIG-IP VE cluster (Active/Active) in Amazon AWS. It uses [AWS Autoscaling Groups (ASG)](https://docs.aws.amazon.com/autoscaling/ec2/userguide/AutoScalingGroup.html) to allow auto scaling and auto healing of the BIG-IP VE devices. Traffic flows from an AWS Network Load Balancer (NLB) to the BIG-IP VE which then processes the traffic to application servers. The BIG-IP VE instance is running with one interface shared by management and data. NIC0 is associated with the external network and used in ASGs. **NOTE: NIC-SWAP happens on mgmt interface**

This solution leverages more traditional Auto Scale configuration management practices where each instance is created with an identical configuration as defined in the Scale Set's "model". Scale Set sizes are no longer restricted to the small limitations of the cluster. The BIG-IP's configuration, now defined in a single convenient YAML or JSON [F5 BIG-IP Runtime Init](https://github.com/F5Networks/f5-bigip-runtime-init) configuration file, leverages [F5 Automation Tool Chain](https://www.f5.com/pdf/products/automation-toolchain-overview.pdf) declarations which are easier to author, validate and maintain as code. For instance, if you need to change the configuration on the BIG-IPs in the deployment, you update the instance model by passing a new config file (which references the updated Automation Toolchain declarations) via template's runtimeConfig input parameter. New instances will be deployed with the updated configurations.

## Version
This template is tested and worked in the following versions:
| Name | Version |
| ---- | ------- |
| terraform | ~> 0.14 |
| aws | ~> 3 |


## Prerequisites

- This template requires programmatic API credentials to deploy the Terraform AWS provider and build out all the neccessary AWS objects
  - See the [Terraform "AWS Provider"](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication) for details
  - You will require at minimum `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
  - ***Note***: Make sure to [practice least privilege](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- This templates deploys into an *EXISTING* networking stack. You are required to have an existing VPC network and subnets
  - A NAT gateway is also required for outbound Internet traffic
  - If you require a new network first, see the [Infrastructure Only folder](../Infrastructure-only) to get started


## Important Configuration Notes

- Variables are configured in variables.tf
- Sensitive variables like AWS SSH keys are configured in terraform.tfvars or AWS Secrets Manager
- Files
  - main.tf - resources for provider, versions
  - bigip.tf - resources for BIG-IP autoscaling group, launch template, security groups
  - nlb.tf - resources for AWS NLB
  - f5_onboard.tmpl - onboarding script which is run by user-data. This script is responsible for downloading the neccessary F5 Automation Toolchain RPM files, installing them, and then executing the onboarding REST calls.

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

## Template Parameters

## Inputs

| Parameter | Description | Type | Default | Required |
| --------- | ----------- | ---- | ------- | -------- |
| projectPrefix | This value is inserted at the beginning of each AWS object (alpha-numeric, no special character) | `string` | myDemo | no |
| f5_username | User name for the BIG-IP (Note: currenlty not used. Defaults to 'admin' based on AMI | `string` | admin | no |
| f5_password | BIG-IP Password | `string` | Default12345! | no |
| f5_ssh_publickey | SSH public key (same key you store in 'ec2_key_name', format should be ssh-rsa like "ssh-rsa AAAA....") | `string` | n/a | no |
| ec2_key_name | SSH public key for admin authentation | `string` | n/a | yes |
| allowedIps | Trusted source network for admin access | `list` | ["0.0.0.0/0"] | yes |
| awsRegion | AWS Region for provider | `string` | us-west-2 | yes |
| vpcId | The AWS network VPC ID | `string` | n/a | yes |
| extSubnetAz1 | External subnet AZ1 | `string` | n/a | yes |
| extSubnetAz2 | Internal subnet AZ2 | `string` | n/a | yes |
| f5_ami_search_name | AWS AMI search filter to find correct BIG-IP VE for region | `string` | F5 BIGIP-15.1.2.1* PAYG-Best 200Mbps* | no |
| ec2_instance_type | AWS instance type for the BIG-IP | `string` | m5.xlarge | no |
| ntp_server | NTP server used by BIG-IP | `string` | 169.254.169.123 | no |
| timezone | Timezone used by BIG-IP clock (ex: UTC, US/Pacific, US/Eastern, Europe/London or Asia/Singapore) | `string` | UTC | no |
| onboard_log | This is where the onboarding script logs all the events | `string` | /var/log/cloud/onboard.log | no |
| bigIqHost | This is the BIG-IQ License Manager host name or IP address | `string` | 200.200.200.200 | no |
| bigIqUsername | BIG-IQ user name | `string` | admin | no |
| bigIqPassword | BIG-IQ Password | `string` | Default12345! | no |
| bigIqLicenseType | BIG-IQ license type | `string` | licensePool | no |
| bigIqLicensePool | BIG-IQ license pool name | `string` | myPool | no |
| bigIqSkuKeyword1 | BIG-IQ license SKU keyword 1 | `string` | key1 | no |
| bigIqSkuKeyword2 | BIG-IQ license SKU keyword 1 | `string` | key2 | no |
| bigIqUnitOfMeasure | BIG-IQ license unit of measure | `string` | hourly | no |
| bigIqHypervisor | BIG-IQ hypervisor | `string` | aws | no |
| asg_min_size | AWS autoscailng minimum size | `string` | 1 | no |
| asg_max_size | AWS autoscailng maximum size | `string` | 2 | no |
| asg_desired_capacity | AWS autoscailng desired capacity | `string` | 1 | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| asg_name | AWS autoscaling group name of BIG-IP devices |
| public_vip | AWS NLB DNS name |
| public_vip_url | http URL link for AWS NLB DNS name |

## Installation Example

To run this Terraform template, perform the following steps:
  1. Clone the repo to your favorite location
  2. Modify terraform.tfvars with the required information
  ```
      # BIG-IP Environment
      allowedIps        = ["0.0.0.0/0"]
      vpcId             = "vpc-1234"
      extSubnetAz1      = "subnet-1234"
      extSubnetAz2      = "subnet-5678"
      ec2_key_name      = "mykey123"
      f5_ssh_publickey  = "ssh-rsa AAABC123....."
      f5_username       = "admin"
      f5_password       = "Default12345!"

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

The following is an example configuration diagram for this solution deployment. In this scenario, all access to the BIG-IP VE cluster (Active/Active) is via a bastion host. The IP addresses in this example may be different in your implementation.

![Configuration Example](./images/autoscale-ltm-nlb.png)

## Documentation

For more information on F5 solutions for AWS, including manual configuration procedures for some deployment scenarios, see the AWS section of [F5 CloudDocs](https://clouddocs.f5.com/cloud/public/v1/aws_index.html). Also check out the [Using Cloud Templates for BIG-IP in AWS](https://devcentral.f5.com/s/articles/Using-Cloud-Templates-to-Change-BIG-IP-Versions-AWS) on DevCentral.
