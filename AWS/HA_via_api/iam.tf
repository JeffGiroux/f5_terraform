# Create IAM Role

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

data "aws_iam_policy_document" "bigip_policy" {
  version = "2012-10-17"
  statement {
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeAddresses",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeNetworkInterfaceAttribute",
      "ec2:DescribeRouteTables",
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation",
      "ec2:AssociateAddress",
      "ec2:DisassociateAddress",
      "ec2:AssignPrivateIpAddresses",
      "ec2:UnassignPrivateIpAddresses"
    ]
    resources = ["*"]
    effect    = "Allow"
  }
  statement {
    actions = [
      "ec2:CreateRoute",
      "ec2:ReplaceRoute"
    ]
    resources = ["*"]
    effect    = "Allow"
  }
  statement {
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketTagging"
    ]
    resources = [aws_s3_bucket.main.arn]
    effect    = "Allow"
  }
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = ["${aws_s3_bucket.main.arn}/*"]
    effect    = "Allow"
  }
}

resource "aws_iam_role" "bigip_role" {
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
  name = format("%s-bigip-profile-%s", var.projectPrefix, random_id.buildSuffix.hex)
  role = aws_iam_role.bigip_role.name
}
