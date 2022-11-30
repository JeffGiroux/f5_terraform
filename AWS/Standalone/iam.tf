# Create IAM Role

# Note: Only created if variable 'aws_iam_instance_profile' is not
#       supplied by user. If you have your own IAM role, make sure
#       the policy includes access to AWS Secrets Managers.

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
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:ListSecrets"
    ]
    resources = ["*"]
    effect    = "Allow"
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
