# Deploying Infrastructure-Only in Google GCP

## Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Important Configuration Notes](#important-configuration-notes)
- [Installation Example](#installation-example)

## Introduction

This solution uses a Terraform template to launch a new networking stack. It will create one VPC network and subnet for management traffic, and it will create a second VPC network and subnet for data traffic (client/server). Use this terraform template to create your Google VPC infrastructure, and then head back to the [BIG-IP GCP Terraform folder](../) to get started!

Terraform is beneficial as it allows composing resources a bit differently to account for dependencies into Immutable/Mutable elements. For example, mutable includes items you would typically frequently change/mutate, such as traditional configs on the BIG-IP. Once the template is deployed, there are certain resources (network infrastructure) that are fixed while others (BIG-IP VMs and configurations) can be changed.

## Version
This template is tested and worked in the following version
Terraform v0.12.26
+ provider.google v3.24

## Prerequisites

- This template requires a service account to deploy with the Terraform Google provider and build out all the neccessary Google objects
  - ***Note***: See the [Terraform Google Provider "Adding Credentials"](https://www.terraform.io/docs/providers/google/guides/getting_started.html#adding-credentials) for details. Also, review the [available Google GCP permission scopes](https://cloud.google.com/sdk/gcloud/reference/alpha/compute/instances/set-scopes#--scopes) too.
  - Permissions will depend on the objects you are creating
  - My Terraform deployments use a service account with the following persmissions:
    - "Editor"
    - "Compute Admin"
    - "Pub/Sub Admin"
    - "Secret Manager Secret Accessor"
    - "API Keys Admin"
    - "Storage Admin"
  - ***Note***: Some of the permissions I listed above may or may not apply to this particular repo folder. For example, performing autoscale will require Pub/Sub permissions. However, deploying a standalone BIG-IP does not require such access. Therefore, [practice least privilege](https://cloud.google.com/iam/docs/understanding-service-accounts#granting_minimum) on your accounts when possible.

## Important Configuration Notes

- Variables are configured in variables.tf
- Sensitive variables like Google SSH keys are configured in terraform.tfvars
  - ***Note***: Other items like BIG-IP password are stored in Google Cloud Secret Manager. Refer to the [Prerequisites](#prerequisites).
- Files
  - main.tf - resources for provider, versions, storage bucket
  - network.tf - resources for VPCs, subnets, firewall rules

## Template Parameters

| Parameter | Required | Description |
| --- | --- | --- |
| prefix | Yes | This value is inserted at the beginning of each Google object (alpha-numeric, no special character) |
| adminSrcAddr | Yes | Trusted source network for admin access |
| gcp_project_id | Yes | GCP Project ID for provider |
| gcp_zone | Yes | GCP Zone for provider |
| gcp_region | Yes | GCP Region for provider |
| cidr_range_mgmt | Yes | IP CIDR range for management VPC network |
| cidr_range_ext | Yes | IP CIDR range for external VPC network |

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
