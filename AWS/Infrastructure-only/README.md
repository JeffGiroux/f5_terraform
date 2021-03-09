# Deploying Infrastructure-Only in AWS

## Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Important Configuration Notes](#important-configuration-notes)
- [Installation Example](#installation-example)

## Introduction

This solution uses a Terraform template to launch a new networking stack. It will create one VPC with three subnets: mgmt, external, internal. Use this Terraform template to create your AWS VPC infrastructure, and then head back to the [BIG-IP AWS Terraform folder](../) to get started!

Terraform is beneficial as it allows composing resources a bit differently to account for dependencies into Immutable/Mutable elements. For example, mutable includes items you would typically frequently change/mutate, such as traditional configs on the BIG-IP. Once the template is deployed, there are certain resources (network infrastructure) that are fixed while others (BIG-IP VMs and configurations) can be changed.

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

## Important Configuration Notes

- Variables are configured in variables.tf
- Sensitive variables like AWS SSH keys are configured in terraform.tfvars
  - ***Note***: Other items like BIG-IP password are stored in AWS Secrets Manager. Refer to the [Prerequisites](#prerequisites).
- Files
  - main.tf - resources for provider, versions
  - network.tf - resources for VPC, subnets, route tables, and internet gateway

## Inputs

| Parameter | Description | Type | Default | Required |
| --------- | ----------- | ---- | ------- | -------- |
| awsRegion | aws region | `string` | us-west-2 | no |
| projectPrefix | project name, will be used as prefix for resource names | `string` | myDemo | no |
| resourceOwner | owner of the deployment, for tagging purposes | `string` | myName | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| subnets_public | public subnets in az1 and az2 |
| subnets_private | private subnets in az1 and az2 |
| subnets_mgmt | mgmt subnets in az1 and az2 |
| vpc_id | vpc id |

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
      awsRegion     = "us-west-2"
      projectPrefix = "myDemo"
      resourceOwner = "myName"
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
  