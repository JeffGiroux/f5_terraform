# Deploying Infrastructure-Only in Google GCP

## Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Important Configuration Notes](#important-configuration-notes)
- [Installation Example](#installation-example)

## Introduction

This solution uses a Terraform template to launch a new networking stack. It will create three VPC networks with one subnet each: mgmt, external, internal. Use this terraform template to create your Google VPC infrastructure, and then head back to the [BIG-IP GCP Terraform folder](../) to get started!

## Prerequisites

- This template requires a service account to deploy with the Terraform Google provider and build out all the neccessary Google objects
  - See the [Terraform Google Provider "Adding Credentials"](https://www.terraform.io/docs/providers/google/guides/getting_started.html#adding-credentials) for details. Also, review the [available Google GCP permission scopes](https://cloud.google.com/sdk/gcloud/reference/alpha/compute/instances/set-scopes#--scopes) too.
  - Permissions will depend on the objects you are creating
  - My service account for Terraform deployments in GCP uses the following roles:
    - Compute Admin
    - Storage Admin
    - Service Account User
    - Service Account Admin
    - Project IAM Admin
  - ***Note***: Make sure to [practice least privilege](https://cloud.google.com/iam/docs/understanding-service-accounts#granting_minimum)

## Important Configuration Notes

- Variables are configured in variables.tf
- Sensitive variables like Google SSH keys are configured in terraform.tfvars
  - ***Note***: Other items like BIG-IP password are stored in Google Cloud Secret Manager. Refer to the [Prerequisites](#prerequisites).
- Files
  - main.tf - resources for provider, versions, storage bucket
  - network.tf - resources for VPCs, subnets, firewall rules
<!-- markdownlint-disable no-inline-html -->
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | >= 4.57.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 4.57.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.4.3 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [google_compute_firewall.app](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.app-ilb-probe](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.default-allow-internal-ext](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.default-allow-internal-int](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.default-allow-internal-mgmt](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.mgmt](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_firewall.one_nic](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_network.vpc_ext](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_network.vpc_int](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_network.vpc_mgmt](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network) | resource |
| [google_compute_subnetwork.vpc_ext_sub](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_compute_subnetwork.vpc_int_sub](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [google_compute_subnetwork.vpc_mgmt_sub](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_subnetwork) | resource |
| [random_id.buildSuffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_adminSrcAddr"></a> [adminSrcAddr](#input\_adminSrcAddr) | Allowed Admin source IP prefix | `string` | `"0.0.0.0/0"` | no |
| <a name="input_ext_address_prefix"></a> [ext\_address\_prefix](#input\_ext\_address\_prefix) | External subnet address prefix | `string` | `"10.1.10.0/24"` | no |
| <a name="input_f5_cloud_failover_label"></a> [f5\_cloud\_failover\_label](#input\_f5\_cloud\_failover\_label) | This is a tag used for F5 Cloud Failover Extension to identity which cloud objects to move during a failover event. | `string` | `"myFailover"` | no |
| <a name="input_gcp_project_id"></a> [gcp\_project\_id](#input\_gcp\_project\_id) | GCP Project ID for provider | `string` | `null` | no |
| <a name="input_gcp_region"></a> [gcp\_region](#input\_gcp\_region) | GCP Region for provider | `string` | `"us-west1"` | no |
| <a name="input_gcp_zone_1"></a> [gcp\_zone\_1](#input\_gcp\_zone\_1) | GCP Zone 1 for provider | `string` | `"us-west1-a"` | no |
| <a name="input_int_address_prefix"></a> [int\_address\_prefix](#input\_int\_address\_prefix) | Internal subnet address prefix | `string` | `"10.1.20.0/24"` | no |
| <a name="input_mgmt_address_prefix"></a> [mgmt\_address\_prefix](#input\_mgmt\_address\_prefix) | Management subnet address prefix | `string` | `"10.1.1.0/24"` | no |
| <a name="input_projectPrefix"></a> [projectPrefix](#input\_projectPrefix) | This value is inserted at the beginning of each Google object (alpha-numeric, no special character) | `string` | `"demo"` | no |
| <a name="input_resourceOwner"></a> [resourceOwner](#input\_resourceOwner) | This is a tag used for object creation. Example is last name. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_external_subnet_name"></a> [external\_subnet\_name](#output\_external\_subnet\_name) | External subnet name |
| <a name="output_external_vpc"></a> [external\_vpc](#output\_external\_vpc) | External VPC name |
| <a name="output_internal_subnet_name"></a> [internal\_subnet\_name](#output\_internal\_subnet\_name) | Internal subnet name |
| <a name="output_internal_vpc"></a> [internal\_vpc](#output\_internal\_vpc) | Internal VPC name |
| <a name="output_mgmt_subnet_name"></a> [mgmt\_subnet\_name](#output\_mgmt\_subnet\_name) | Management subnet name |
| <a name="output_mgmt_vpc"></a> [mgmt\_vpc](#output\_mgmt\_vpc) | Management VPC name |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- markdownlint-enable no-inline-html -->

## Installation Example

To run this Terraform template, perform the following steps:
  1. Clone the repo to your favorite location
  2. Modify terraform.tfvars with the required information
  ```
      # Google Environment
      projectPrefix  = "mydemo123"
      adminSrcAddr   = "0.0.0.0/0"
      gcp_project_id = "xxxxx"
      gcp_region     = "us-west1"
      gcp_zone_1     = "us-west1-a"
      resourceOwner  = "mylastname"
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

## Documentation

Visit DevCentral to read [Service Discovery in Google Cloud with F5 BIG-IP](https://devcentral.f5.com/s/articles/Service-Discovery-in-Google-Cloud-with-F5-BIG-IP) where I show you my basic VPC setup (networks, subnets) along with firewall rules.
