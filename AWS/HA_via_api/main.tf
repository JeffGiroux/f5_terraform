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

# Create the Storage Account
resource "aws_s3_bucket" "main" {
  bucket        = format("%sstorage%s", var.projectPrefix, random_id.buildSuffix.hex)
  force_destroy = true
  tags = {
    Name                    = format("%sstorage%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner                   = var.resourceOwner
    f5_cloud_failover_label = format("%s-%s", var.projectPrefix, random_id.buildSuffix.hex)
  }
}

# Retrieve AWS VPC info
data "aws_vpc" "main" {
  id = var.vpcId
}
