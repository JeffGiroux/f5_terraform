# Deploying Infrastructure-Only in AWS

## Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Important Configuration Notes](#important-configuration-notes)
- [Installation Example](#installation-example)

## Introduction

This solution uses a Terraform template to launch a new networking stack. It will create one VPC with three subnets: mgmt, external, internal. Use this Terraform template to create your AWS VPC infrastructure, and then head back to the [BIG-IP AWS Terraform folder](../) to get started!

## Prerequisites

- This template requires programmatic API credentials to deploy the Terraform AWS provider and build out all the neccessary AWS objects
  - See the [Terraform "AWS Provider"](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication) for details
  - You will require at minimum `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`
  - ***Note***: Make sure to [practice least privilege](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

## Important Configuration Notes

- Variables are configured in variables.tf
- Sensitive variables like AWS SSH keys are configured in terraform.tfvars
- Files
  - main.tf - resources for provider, versions
  - network.tf - resources for VPC, subnets, route tables, internet gateway, security groups

## Installation Example

To run this Terraform template, perform the following steps:
  1. Clone the repo to your favorite location
  2. Update AWS credentials
  ```
      export AWS_ACCESS_KEY_ID=<your-access-keyId>
      export AWS_SECRET_ACCESS_KEY=<your-secret-key>
  ```
  3. Modify terraform.tfvars with the required information
  ```
      projectPrefix = "myDemo"
      resourceOwner = "myName"
      awsRegion     = "us-west-2"
      awsAz1        = "us-west-2a"
      awsAz2        = "us-west-2b"
  ```
  4. Initialize the directory
  ```
      terraform init
  ```
  5. Test the plan and validate errors
  ```
      terraform plan
  ```
  6. Finally, apply and deploy
  ```
      terraform apply
  ```
  7. When done with everything, don't forget to clean up!
  ```
      terraform destroy
  ```

<!-- markdownlint-disable no-inline-html -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.59.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.59.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.4.3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | ~> 3.0 |

## Resources

| Name | Type |
|------|------|
| [aws_route_table_association.mgmtAz1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.mgmtAz2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.external](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.internal](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.mgmt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.mgmtAz1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.mgmtAz2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [random_id.buildSuffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_adminSrcAddr"></a> [adminSrcAddr](#input\_adminSrcAddr) | Allowed Admin source IP prefix | `string` | `"0.0.0.0/0"` | no |
| <a name="input_awsAz1"></a> [awsAz1](#input\_awsAz1) | Availability zone, will dynamically choose one if left empty | `string` | `"us-west-2a"` | no |
| <a name="input_awsAz2"></a> [awsAz2](#input\_awsAz2) | Availability zone, will dynamically choose one if left empty | `string` | `"us-west-2b"` | no |
| <a name="input_awsRegion"></a> [awsRegion](#input\_awsRegion) | aws region | `string` | `"us-west-2"` | no |
| <a name="input_ext_address_prefixes"></a> [ext\_address\_prefixes](#input\_ext\_address\_prefixes) | External subnet address prefixes | `list(any)` | <pre>[<br>  "10.1.10.0/24",<br>  "10.1.110.0/24"<br>]</pre> | no |
| <a name="input_int_address_prefixes"></a> [int\_address\_prefixes](#input\_int\_address\_prefixes) | Internal subnet address prefixes | `list(any)` | <pre>[<br>  "10.1.20.0/24",<br>  "10.1.120.0/24"<br>]</pre> | no |
| <a name="input_mgmt_address_prefixes"></a> [mgmt\_address\_prefixes](#input\_mgmt\_address\_prefixes) | Management subnet address prefixes | `list(any)` | <pre>[<br>  "10.1.1.0/24",<br>  "10.1.100.0/24"<br>]</pre> | no |
| <a name="input_projectPrefix"></a> [projectPrefix](#input\_projectPrefix) | This value is inserted at the beginning of each AWS object (alpha-numeric, no special character) | `string` | `"demo"` | no |
| <a name="input_resourceOwner"></a> [resourceOwner](#input\_resourceOwner) | This is a tag used for object creation. Example is last name. | `string` | `null` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | CIDR IP Address range of the VPC | `string` | `"10.1.0.0/16"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_extNsg"></a> [extNsg](#output\_extNsg) | ID of External security group |
| <a name="output_extSubnetAz1"></a> [extSubnetAz1](#output\_extSubnetAz1) | ID of External subnet AZ1 |
| <a name="output_extSubnetAz2"></a> [extSubnetAz2](#output\_extSubnetAz2) | ID of External subnet AZ2 |
| <a name="output_intNsg"></a> [intNsg](#output\_intNsg) | ID of Internal security group |
| <a name="output_intSubnetAz1"></a> [intSubnetAz1](#output\_intSubnetAz1) | ID of Internal subnet AZ1 |
| <a name="output_intSubnetAz2"></a> [intSubnetAz2](#output\_intSubnetAz2) | ID of Internal subnet AZ2 |
| <a name="output_mgmtNsg"></a> [mgmtNsg](#output\_mgmtNsg) | ID of Management security group |
| <a name="output_mgmtSubnetAz1"></a> [mgmtSubnetAz1](#output\_mgmtSubnetAz1) | ID of Management subnet AZ1 |
| <a name="output_mgmtSubnetAz2"></a> [mgmtSubnetAz2](#output\_mgmtSubnetAz2) | ID of Management subnet AZ2 |
| <a name="output_vpcId"></a> [vpcId](#output\_vpcId) | VPC ID |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- markdownlint-enable no-inline-html -->
