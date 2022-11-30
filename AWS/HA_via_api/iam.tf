# IAM Role

# Note: Only created if variable 'aws_iam_instance_profile' is not
#       supplied by user.

# Retrieve account info
data "aws_caller_identity" "main" {}

# Create IAM role
data "aws_iam_policy_document" "bigip_role" {
  version = "2012-10-17"
  statement {
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Create IAM policy
data "aws_iam_policy_document" "bigip_policy" {
  version = "2012-10-17"
  statement {
    sid = "secretsListAll"
    actions = [
      "secretsmanager:ListSecrets"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    sid = "secretsGetValue"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
    ]
    effect    = "Allow"
    resources = [var.aws_secretmanager_secret_id == null ? "arn:aws:secretsmanager:::secret:mySecret123" : var.aws_secretmanager_secret_id]
  }
  statement {
    sid = "cfeGetDeviceInfo"
    actions = [
      "ec2:DescribeAddresses",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeNetworkInterfaceAttribute",
      "ec2:DescribeTags"
    ]
    effect    = "Allow"
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.awsRegion]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = [data.aws_caller_identity.main.account_id]
    }
  }
  statement {
    sid = "cfeGetNetworkInfo"
    actions = [
      "ec2:DescribeSubnets",
      "ec2:DescribeRouteTables"
    ]
    effect    = "Allow"
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.awsRegion]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = [data.aws_caller_identity.main.account_id]
    }
  }
  statement {
    sid = "cfeUpdateObjects"
    actions = [
      "ec2:AssociateAddress",
      "ec2:DisassociateAddress",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses",
      "ec2:AssignIpv6Addresses",
      "ec2:UnassignIpv6Addresses",
      "ec2:CreateRoute",
      "ec2:ReplaceRoute"
    ]
    effect    = "Allow"
    resources = ["*"]
    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/f5_cloud_failover_label"
      values   = [var.f5_cloud_failover_label]
    }
  }
  statement {
    sid = "cfeListAllBuckets"
    actions = [
      "s3:ListAllMyBuckets"
    ]
    effect    = "Allow"
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = [data.aws_caller_identity.main.account_id]
    }
  }
  statement {
    sid = "cfeGetBucketInfo"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketTagging"
    ]
    effect    = "Allow"
    resources = ["arn:*:s3:::${aws_s3_bucket.main.id}"]
  }
  statement {
    sid = "cfeUpdateBucketInfo"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    effect    = "Allow"
    resources = ["arn:*:s3:::${aws_s3_bucket.main.id}/*"]
  }
  statement {
    sid = "cfeBucketDenyPublishingUnencryptedResources"
    actions = [
      "s3:PutObject"
    ]
    effect    = "Deny"
    resources = ["arn:*:s3:::${aws_s3_bucket.main.id}/*"]
    condition {
      test     = "Null"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["true"]
    }
  }
  statement {
    sid = "cfeBucketDenyIncorrectEncryptionHeader"
    actions = [
      "s3:PutObject"
    ]
    effect    = "Deny"
    resources = ["arn:*:s3:::${aws_s3_bucket.main.id}/*"]
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["AES256"]
    }
  }
}

resource "aws_iam_role" "bigip_role" {
  count              = var.aws_iam_instance_profile == null ? 1 : 0
  name               = format("%s-bigip-role-%s", var.projectPrefix, random_id.buildSuffix.hex)
  assume_role_policy = data.aws_iam_policy_document.bigip_role.json
  inline_policy {
    name   = "bigip-policy"
    policy = data.aws_iam_policy_document.bigip_policy.json
  }
  tags = {
    Name  = format("%s-bigip-role-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}

resource "aws_iam_instance_profile" "bigip_profile" {
  count = var.aws_iam_instance_profile == null ? 1 : 0
  name  = format("%s-bigip-profile-%s", var.projectPrefix, random_id.buildSuffix.hex)
  role  = aws_iam_role.bigip_role[0].name
}
