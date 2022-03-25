# Deploying Infrastructure-Only in Azure

## Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Important Configuration Notes](#important-configuration-notes)
- [Installation Example](#installation-example)

## Introduction

This solution uses a Terraform template to launch a new networking stack. It will create one VNET with three subnets: mgmt, external, internal. Use this Terraform template to create your Azure VNET infrastructure, and then head back to the [BIG-IP Azure Terraform folder](../) to get started!

Terraform is beneficial as it allows composing resources a bit differently to account for dependencies into Immutable/Mutable elements. For example, mutable includes items you would typically frequently change/mutate, such as traditional configs on the BIG-IP. Once the template is deployed, there are certain resources (network infrastructure) that are fixed while others (BIG-IP VMs and configurations) can be changed.

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
  - main.tf - resources for provider, versions
  - network.tf - resources for VNET, subnets, security groups


<!-- markdownlint-disable no-inline-html -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14.5 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | >= 3 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_network_security_group.external](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_network_security_group.mgmt](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_resource_group.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_subnet.external](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.internal](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet.mgmt](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet) | resource |
| [azurerm_subnet_network_security_group_association.external](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_subnet_network_security_group_association.mgmt](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | resource |
| [azurerm_virtual_network.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_adminSrcAddr"></a> [adminSrcAddr](#input\_adminSrcAddr) | Allowed Admin source IP prefix | `string` | `"0.0.0.0/0"` | no |
| <a name="input_ext_address_prefix"></a> [ext\_address\_prefix](#input\_ext\_address\_prefix) | External subnet address prefix | `string` | `"10.90.2.0/24"` | no |
| <a name="input_f5_cloud_failover_label"></a> [f5\_cloud\_failover\_label](#input\_f5\_cloud\_failover\_label) | This is a tag used for F5 Cloud Failover Extension to identity which cloud objects to move during a failover event. | `string` | `"mydeployment"` | no |
| <a name="input_int_address_prefix"></a> [int\_address\_prefix](#input\_int\_address\_prefix) | Internal subnet address prefix | `string` | `"10.90.3.0/24"` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure Location of the deployment | `string` | `"westus2"` | no |
| <a name="input_mgmt_address_prefix"></a> [mgmt\_address\_prefix](#input\_mgmt\_address\_prefix) | Management subnet address prefix | `string` | `"10.90.1.0/24"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | This is a tag used for object creation. Example is last name. | `string` | `null` | no |
| <a name="input_projectPrefix"></a> [projectPrefix](#input\_projectPrefix) | This value is inserted at the beginning of each Azure object (alpha-numeric, no special character) | `string` | `"demo"` | no |
| <a name="input_vnet_cidr"></a> [vnet\_cidr](#input\_vnet\_cidr) | CIDR IP Address range of the Virtual Network | `string` | `"10.90.0.0/16"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_external_subnet"></a> [external\_subnet](#output\_external\_subnet) | External subnet address prefix |
| <a name="output_internal_subnet"></a> [internal\_subnet](#output\_internal\_subnet) | Internal subnet address prefix |
| <a name="output_mgmt_subnet"></a> [mgmt\_subnet](#output\_mgmt\_subnet) | Management subnet address prefix |
| <a name="output_resource_group"></a> [resource\_group](#output\_resource\_group) | Resource group name |
| <a name="output_vnet"></a> [vnet](#output\_vnet) | VNet name |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- markdownlint-enable no-inline-html -->

## Installation Example

To run this Terraform template, perform the following steps:
  1. Clone the repo to your favorite location
  2. Modify terraform.tfvars with the required information
  ```
      # Azure Environment
      location     = "westus2"
      adminSrcAddr = "0.0.0.0/0"

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
