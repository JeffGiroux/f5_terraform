# Deploying Infrastructure-Only in Azure

## Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Important Configuration Notes](#important-configuration-notes)
- [Installation Example](#installation-example)

## Introduction

This solution uses a Terraform template to launch a new networking stack. It will create one VNET with three subnets: mgmt, external, internal. Use this Terraform template to create your Azure VNET infrastructure, and then head back to the [BIG-IP Azure Terraform folder](../) to get started!

Terraform is beneficial as it allows composing resources a bit differently to account for dependencies into Immutable/Mutable elements. For example, mutable includes items you would typically frequently change/mutate, such as traditional configs on the BIG-IP. Once the template is deployed, there are certain resources (network infrastructure) that are fixed while others (BIG-IP VMs and configurations) can be changed.

## Version
This template is tested and worked in the following version
Terraform v0.14.6
+ provider.azurerm v2.48

## Prerequisites

- This template requires a service account to deploy with the Terraform Azure provider and build out all the neccessary Azure objects
  - See the [Terraform Azure Provider "Authenticating Using a Service Principal"](https://www.terraform.io/docs/providers/azurerm/guides/service_principal_client_secret.html) for details. Also, review the [available Azure built-in roles](https://docs.microsoft.com/en-gb/azure/role-based-access-control/built-in-roles) too.
  - Permissions will depend on the objects you are creating
  - My service account for Terraform deployments in Azure uses the following roles:
    - Contributor
  - ***Note***: Make sure to [practice least privilege](https://docs.microsoft.com/en-us/azure/security/fundamentals/identity-management-best-practices#lower-exposure-of-privileged-accounts)

## Important Configuration Notes

- Variables are configured in variables.tf
- Sensitive variables like Azure SSH keys are configured in terraform.tfvars
  - ***Note***: Other items like BIG-IP password are stored in Azure Key Vault. Refer to the [Prerequisites](#prerequisites).
- Files
  - main.tf - resources for provider, versions, storage account
  - network.tf - resources for VNET, subnets, security groups

## Template Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| prefix | Yes | This value is inserted at the beginning of each Azure object (alpha-numeric, no special character) |
| adminSrcAddr | Yes | Trusted source network for admin access |
| sp_subscription_id | Yes | This is the service principal subscription ID |
| sp_client_id | Yes | This is the service principal application/client ID |
| sp_client_secret | Yes | This is the service principal secret |
| sp_tenant_id | Yes | This is the service principal tenant ID |
| vnet_cidr | Yes | IP address CIDR range for VNET |
| mgmt_address_prefix | Yes | IP address prefix for management subnet |
| ext_address_prefix | Yes | IP address prefix for external subnet |
| int_address_prefix | Yes | IP address prefix for internal subnet |

## Installation Example

To run this Terraform template, perform the following steps:
  1. Clone the repo to your favorite location
  2. Modify terraform.tfvars with the required information
  ```
      # Azure Environment
      sp_subscription_id = "xxxxx"
      sp_client_id       = "xxxxx"
      sp_client_secret   = "xxxxx"
      sp_tenant_id       = "xxxxx"
      location           = "westus2"
      adminSrcAddr       = "0.0.0.0/0"

      # Prefix for objects being created
      prefix = "mydemo123"
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
  