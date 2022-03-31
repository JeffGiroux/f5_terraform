# Main

# Terraform Version Pinning
terraform {
  required_version = ">= 0.14"
  required_providers {
    aws = ">= 4"
  }
}

# AWS Provider
provider "aws" {
  region = var.awsRegion
}

# Create a random id
resource "random_id" "buildSuffix" {
  byte_length = 2
}

# Retrieve AWS VPC info
data "aws_vpc" "main" {
  id = var.vpcId
}
