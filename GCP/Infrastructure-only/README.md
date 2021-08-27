# Deploying Infrastructure-Only in Google GCP

## Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Important Configuration Notes](#important-configuration-notes)
- [Installation Example](#installation-example)

## Introduction

This solution uses a Terraform template to launch a new networking stack. It will create three VPC networks with one subnet each: mgmt, external, internal. Use this terraform template to create your Google VPC infrastructure, and then head back to the [BIG-IP GCP Terraform folder](../) to get started!

Terraform is beneficial as it allows composing resources a bit differently to account for dependencies into Immutable/Mutable elements. For example, mutable includes items you would typically frequently change/mutate, such as traditional configs on the BIG-IP. Once the template is deployed, there are certain resources (network infrastructure) that are fixed while others (BIG-IP VMs and configurations) can be changed.


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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 0.14 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | ~> 3 |

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
| [google_storage_bucket.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_adminSrcAddr"></a> [adminSrcAddr](#input\_adminSrcAddr) | Trusted source network for admin access | `string` | `"0.0.0.0/0"` | no |
| <a name="input_cidr_range_ext"></a> [cidr\_range\_ext](#input\_cidr\_range\_ext) | IP CIDR range for external VPC network | `string` | `"10.1.10.0/24"` | no |
| <a name="input_cidr_range_int"></a> [cidr\_range\_int](#input\_cidr\_range\_int) | IP CIDR range for internal VPC network | `string` | `"10.1.20.0/24"` | no |
| <a name="input_cidr_range_mgmt"></a> [cidr\_range\_mgmt](#input\_cidr\_range\_mgmt) | IP CIDR range for management VPC network | `string` | `"10.1.1.0/24"` | no |
| <a name="input_f5_cloud_failover_label"></a> [f5\_cloud\_failover\_label](#input\_f5\_cloud\_failover\_label) | This is a tag used for F5 Cloud Failover Extension to identity which cloud objects to move during a failover event. | `string` | `"mydeployment"` | no |
| <a name="input_gcp_project_id"></a> [gcp\_project\_id](#input\_gcp\_project\_id) | GCP Project ID for provider | `string` | `null` | no |
| <a name="input_gcp_region"></a> [gcp\_region](#input\_gcp\_region) | GCP Region for provider | `string` | `"us-west1"` | no |
| <a name="input_gcp_zone"></a> [gcp\_zone](#input\_gcp\_zone) | GCP Zone for provider | `string` | `"us-west1-b"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | This is a tag used for object creation. Example is last name. | `string` | `null` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | This value is inserted at the beginning of each Google object (alpha-numeric, no special character) | `string` | `"demo"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_external_subnet"></a> [external\_subnet](#output\_external\_subnet) | External subnet name |
| <a name="output_external_vpc"></a> [external\_vpc](#output\_external\_vpc) | External VPC name |
| <a name="output_internal_subnet"></a> [internal\_subnet](#output\_internal\_subnet) | Internal subnet name |
| <a name="output_internal_vpc"></a> [internal\_vpc](#output\_internal\_vpc) | Internal VPC name |
| <a name="output_mgmt_subnet"></a> [mgmt\_subnet](#output\_mgmt\_subnet) | Management subnet name |
| <a name="output_mgmt_vpc"></a> [mgmt\_vpc](#output\_mgmt\_vpc) | Management VPC name |
| <a name="output_storage_bucket"></a> [storage\_bucket](#output\_storage\_bucket) | Storage bucket name |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
<!-- markdownlint-enable no-inline-html -->

## Installation Example

To run this Terraform template, perform the following steps:
  1. Clone the repo to your favorite location
  2. Modify terraform.tfvars with the required information
  ```
      # Google Environment
      prefix         = "mydemo123"
      adminSrcAddr   = "0.0.0.0/0"
      gcp_project_id = "xxxxx"
      gcp_region     = "us-west1"
      gcp_zone       = "us-west1-b"
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
