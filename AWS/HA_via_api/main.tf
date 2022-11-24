# Main

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
    f5_cloud_failover_label = var.f5_cloud_failover_label
  }
}

# Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Retrieve AWS VPC info
data "aws_vpc" "main" {
  id = var.vpcId
}
