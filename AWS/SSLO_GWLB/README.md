# Description
AWS Gateway Load Balancer and BIG-IP SSL Orchestrator Infrastructure Deployment using Terraform

## To Do
- Community support only. Not F5 supported.

## Issues
- Find an issue? Fork, clone, create branch, fix and PR. I'll review and merge into the main branch. Or submit a GitHub issue with all necessary details and logs.

## Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Important Configuration Notes](#important-configuration-notes)
- [Installation Example](#installation-example)
- [Configuration Example](#configuration-example)
- [Troubleshooting](#troubleshooting)

## Introduction

This solution uses a Terraform template to launch a 7-NIC deployment of a cloud-focused BIG-IP VE device running F5 SSL Orchestrator in AWS with Gateway Load Balancer (GWLB). The [AWS GWLB](https://aws.amazon.com/elasticloadbalancing/gateway-load-balancer/) is included in the architecture and helps to scale and manage third-party virtual appliances like F5 BIG-IP. Traffic flows to AWS Cloud, routes through AWS GWLB, and it is directed towards the BIG-IP devices running SSLO Orchestrator. The BIG-IP processes the traffic, sends it to various security inspection devices, then the traffic is routed back through BIG-IP and AWS GWLB to the final destination.

Note: There are many types of security inspection devices. This demo uses a second BIG-IP device to perform IPS functionality. This is purely for demo purposes.

The resulting deployment will consist of the following:

- Security VPC and subnets
  - 1x [BIG-IP SSL Orchestrator](https://www.f5.com/solutions/service-providers/big-ip-afm-ips-solution-overview)
  - 1x Inspection device running IPS (part of [BIG-IP Advanced Firewall Manager module](https://www.f5.com/solutions/service-providers/big-ip-afm-ips-solution-overview))
  - AWS GWLB
- Application VPC and subnets
  - 1x Wordpress application server
  - AWS GWLB endpoint

## Prerequisites

- ***Important***: When you configure the admin password for the BIG-IP VE in the template, you cannot use the character **#**.  Additionally, there are a number of other special characters that you should avoid using for F5 product user accounts.  See [K2873](https://support.f5.com/csp/article/K2873) for details.
- This template requires one or more service accounts for the BIG-IP instance to perform various tasks:
  - AWS Secrets Manager - requires IAM Profile to retrieve secrets (see [IAM policy examples for secrets in AWS Secrets Manager](https://docs.aws.amazon.com/mediaconnect/latest/ug/iam-policy-examples-asm-secrets.html))
    - Performed by VM instance during onboarding to retrieve passwords and private keys
- This template requires programmatic API credentials to deploy the Terraform AWS provider and build out all the neccessary AWS objects
  - See the [Terraform "AWS Provider"](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication) for details
  - You will require at minimum `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
  - ***Note***: Make sure to [practice least privilege](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- Passwords and secrets can be located in [AWS Secrets Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/intro.html).
  - Set *aws_secretmanager_auth* to 'true'
  - A new IAM profile (aka role and permissions) is created with permissions to list secrets (see iam.tf)
  - If *aws_secretmanager_auth* is 'true', then 'f5_password' should be the ARN of the AWS Secrets Manager secret. The secret needs to contain ONLY the password as 'plain text' type.
- You must subscribe to the following AWS Marketplace offerings:
  - F5 BIG-IP (BYOL, 2boot) - https://aws.amazon.com/marketplace/pp?sku=5f5a1994-65df-4235-b79c-a3ea049dc1db
    - used by BIG-IP SSL Orchestrator device
    - used by BIG-IP IPS inspection device
  - WordPress - https://aws.amazon.com/marketplace/pp?sku=78b1d030-4c7d-4ade-b8e6-f8dc86941303
    - used by demo application server


## Important Configuration Notes

- Variables are configured in variables.tf
- Sensitive variables like AWS SSH keys are configured in terraform.tfvars or AWS Secrets Manager
  - ***Note***: Other items like BIG-IP password can be stored in AWS Secrets Manager. Refer to the [Prerequisites](#prerequisites).
- This template uses BIG-IP Runtime Init for the initial configuration. As part of the onboarding script, it will download the F5 Toolchain RPMs automatically. See the [AS3 documentation](http://f5.com/AS3Docs) and [DO documentation](http://f5.com/DODocs) for details on how to use AS3 and Declarative Onboarding on your BIG-IP VE(s).
  - Terraform does not configure the initial SSL Orchestrator Topology configuration
    - Ansible variables file is automatically generated
    - Ansible playbook is used to deploy an Inbound Layer 3 Topology
    - You can also manually configure and deploy the Topology instead
- Files
  - bigip-sslo.tf - resources for BIG-IP SSL Orchestrator, NICs, public IPs
  - bigip-ips.tf - resources for BIG-IP IPS inspection devices, NICs
  - gwlb.tf - resources for AWS Gateway Load Balancer
  - iam.tf - resources to create IAM roles and permissions
  - network.tf - resources for AWS VPC, subnets, and networking
  - main.tf - resources for provider, versions
  - f5_onboard_sslo.tmpl - onboarding script for the SSLO device which is run by user-data. This script is responsible for downloading the neccessary F5 Automation Toolchain RPM files, installing them, and then executing the onboarding REST calls via the [BIG-IP Runtime Init tool](https://github.com/F5Networks/f5-bigip-runtime-init).
  - f5_onboard_ips.tmpl - onboarding script for the IPS device which is run by user-data. This script is responsible for downloading the neccessary F5 Automation Toolchain RPM files, installing them, and then executing the onboarding REST calls via the [BIG-IP Runtime Init tool](https://github.com/F5Networks/f5-bigip-runtime-init).

## Installation Example

To run this Terraform template, perform the following steps:
  1. Clone the repo to your favorite location
  2. Modify terraform.tfvars with the required information
  ```
      # BIG-IP Environment
      adminSrcAddr  = "0.0.0.0/0"
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

The following is an example configuration diagram for this solution deployment. In this scenario, all access to the BIG-IP VE device is direct to the BIG-IP via the management interface. The IP addresses in this example may be different in your implementation.

![F5 SSLO AWS GWLB](./images/aws-gwlb-sslo.png)

## Steps for Manual SSL Orchestrator Topology Configuration

- [optional] Upload a trusted SSL certificate and key before entering the SSL Orchestrator guide configuration UI

- Create an L3 Inbound topology

- Define SSL settings (using either the default or the previously uploaded certificate and key)

- Create the first inspection service
  - Enter a name for the service
  - Select a Layer 3 type from the service catalog
  - De-select automatic network configuration
  - Use **dmz1** as the To-Service VLAN
  - Enter the IP address of the inspection service (from Terraform outputs)
  - Use **dmz2** as the From-Service VLAN
  - Enable Port remapping (e.g., 8000)

- Create a Service Chain (service_chain_1) and add the first inspection service to it.

- In the Egress settings, use SNAT automap and network default route

- In the Security Policy rules:

  - Add the Service Chain to the Default rule.

- Deploy the Topology configuration.

## Redeploy BIG-IP for Replacement or Upgrade
This example illustrates how to replace or upgrade the BIG-IP VE.
  1. Change the *f5_ami_search_name* variable to the desired release
  2. Revoke the problematic BIG-IP VE's license (if BYOL)
  3. Run command
```
terraform taint module.bigip.aws_instance.f5_bigip
```
  3. Run command
```
terraform apply
```

## Troubleshooting

### Serial Logs
Review the serial logs for the Google virtual machine. Login to the AWS portal, open "EC2", then locate your instance...click it. Hit Actions > Monitor and Troubleshoot > Get stem log. Then review the serial logs for errors.

### Onboard Logs
Depending on where onboard fails, you can attempt SSH login and try to troubleshoot further. Inspect the /config/cloud directory for correct runtime init YAML files. Inspec the /var/log/cloud location for error logs.

### F5 Automation Toolchain Components
F5 BIG-IP Runtime Init uses the F5 Automation Toolchain for configuration of BIG-IP instances.  Any errors thrown from these components will be surfaced in the bigIpRuntimeInit.log (or a custom log location as specified below).

Help with troubleshooting individual Automation Toolchain components can be found at F5's [Public Cloud Docs](http://clouddocs.f5.com/cloud/public/v1/):
- DO: https://clouddocs.f5.com/products/extensions/f5-declarative-onboarding/latest/troubleshooting.html
- AS3: https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/userguide/troubleshooting.html
- FAST: https://clouddocs.f5.com/products/extensions/f5-appsvcs-templates/latest/userguide/troubleshooting.html
- TS: https://clouddocs.f5.com/products/extensions/f5-telemetry-streaming/latest/userguide/troubleshooting.html
- CFE: https://clouddocs.f5.com/products/extensions/f5-cloud-failover/latest/userguide/troubleshooting.html

### Inspection Devices
This configuration uses "inspection" devices sitting in separate service chains to simulate real world deployments. These are BIG-IP devices running the Advanced Firewall Manager module with IPS functionality. Basic configuration is applied in this demo so that packets traverse the inspection zone and return to the SSL Orchestrator interfaces.

If the config fails, you should check where traffic is stopping. A good place to start is at the BIG-IP SSL Orchestrator device first.

- Run a tcpdump on the dmz1 and dmz3 interfaces. Do you see traffic?
  - No: Inspection devices are not configured properly in the SSL Orchestrator Service configuration, Service Chain, or Security Policy. Review your SSL Orchestrator configuration.

  - Yes: Run a tcpdump on the dmz2/dmz4 interface. Do you see traffic?

    - No: The routes on the inspection devices are not set up correctly (possibly due to bootstrap issues).

      - SSH to the inspection device(s) and check the route table.

      - Does the table contain a route for 10.0.2.0/24? If not, validate if cloud-init was successful on BIG-IP inpection devivice. See [Troubleshooting](#troubleshooting) and check logs for onboard delcaration errors.

      - Try to re-run the onboarding scripts and watch logs

        - inspection_device_1:

          ```bash
          f5-bigip-runtime-init --config-file /config/cloud/runtime-init-conf.yaml
          ```

<!-- markdownlint-disable no-inline-html -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- markdownlint-enable no-inline-html -->
