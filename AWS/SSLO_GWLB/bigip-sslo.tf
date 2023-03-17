# BIG-IP SSL Orchestrator

############################ Locals ############################

locals {
  # BIG-IP module subnet "helpers"
  mgmt_subnets = {
    mgmt = {
      subnet_id          = aws_subnet.mgmtAz1.id
      public_ip          = true
      private_ip_primary = "${cidrhost(var.securityMgmtSubnets[0], 11)}"
    }
  }
  ext_subnets = {
    external = {
      subnet_id            = module.securityVpc.public_subnets[0]
      public_ip            = true
      private_ip_primary   = "${cidrhost(var.securityExternalSubnets[0], 11)}"
      private_ip_secondary = "${cidrhost(var.securityExternalSubnets[0], 200)}"
    }
    dmz1 = {
      subnet_id            = aws_subnet.dmz1Az1.id
      public_ip            = false
      private_ip_primary   = "${cidrhost(var.securityDmz1Subnets[0], 7)}"
      private_ip_secondary = "${cidrhost(var.securityDmz1Subnets[0], 8)}"
    }
    dmz2 = {
      subnet_id            = aws_subnet.dmz2Az1.id
      public_ip            = false
      private_ip_primary   = "${cidrhost(var.securityDmz2Subnets[0], 117)}"
      private_ip_secondary = "${cidrhost(var.securityDmz2Subnets[0], 116)}"
    }
    dmz3 = {
      subnet_id            = aws_subnet.dmz3Az1.id
      public_ip            = false
      private_ip_primary   = "${cidrhost(var.securityDmz3Subnets[0], 7)}"
      private_ip_secondary = "${cidrhost(var.securityDmz3Subnets[0], 8)}"
    }
    dmz4 = {
      subnet_id            = aws_subnet.dmz4Az1.id
      public_ip            = false
      private_ip_primary   = "${cidrhost(var.securityDmz4Subnets[0], 117)}"
      private_ip_secondary = "${cidrhost(var.securityDmz4Subnets[0], 116)}"
    }
  }
  int_subnets = {
    internal = {
      subnet_id          = module.securityVpc.private_subnets[0]
      public_ip          = false
      private_ip_primary = "${cidrhost(var.securityInternalSubnets[0], 11)}"
    }
  }
  # BIG-IP module security group "helpers"
  mgmt_security_groups = {
    mgmt = aws_security_group.management.id
  }
  ext_security_groups = {
    external = aws_security_group.external.id
    dmz1     = aws_security_group.inspectionZone.id
    dmz2     = aws_security_group.inspectionZone.id
    dmz3     = aws_security_group.inspectionZone.id
    dmz4     = aws_security_group.inspectionZone.id
  }
  int_security_groups = {
    internal = aws_security_group.internal.id
  }
  # Custom tags
  tags = {
    Owner = var.resourceOwner
  }
}

############################ Secrets Manager ############################

# Validate the secret exists
data "aws_secretsmanager_secret" "password" {
  count = var.aws_secretmanager_auth ? 1 : 0
  name  = var.f5_password
}

data "aws_secretsmanager_secret_version" "current" {
  count     = var.aws_secretmanager_auth ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.password[count.index].id
}

############################ SSH Key pair ############################

# Create SSH Key Pair
resource "aws_key_pair" "bigip" {
  key_name   = format("%s-key-%s", var.projectPrefix, random_id.buildSuffix.hex)
  public_key = var.ssh_key
}

############################ Onboard Scripts ############################

# Setup Onboarding scripts
locals {
  f5_onboard_sslo = templatefile("${path.module}/f5_onboard_sslo.tmpl", {
    license_key            = var.license_sslo
    f5_username            = var.f5_username
    f5_password            = var.aws_secretmanager_auth ? data.aws_secretsmanager_secret_version.current[0].secret_id : var.f5_password
    aws_secretmanager_auth = var.aws_secretmanager_auth
    ssh_keypair            = var.ssh_key
    INIT_URL               = var.INIT_URL
    DO_URL                 = var.DO_URL
    AS3_URL                = var.AS3_URL
    TS_URL                 = var.TS_URL
    FAST_URL               = var.FAST_URL
    DO_VER                 = split("/", var.DO_URL)[7]
    AS3_VER                = split("/", var.AS3_URL)[7]
    TS_VER                 = split("/", var.TS_URL)[7]
    FAST_VER               = split("/", var.FAST_URL)[7]
    sslo_pkg_name          = var.sslo_pkg_name
  })
}

############################ Compute ############################

# Create F5 BIG-IP VMs
module "bigipSslO" {
  source                     = "F5Networks/bigip-module/aws"
  version                    = "1.1.11"
  prefix                     = format("%s-sslo", var.projectPrefix)
  ec2_instance_type          = var.ec2_instance_type
  ec2_key_name               = aws_key_pair.bigip.key_name
  f5_ami_search_name         = var.f5_ami_search_name
  f5_username                = var.f5_username
  mgmt_subnet_ids            = [local.mgmt_subnets.mgmt]
  mgmt_securitygroup_ids     = [local.mgmt_security_groups.mgmt]
  external_subnet_ids        = [local.ext_subnets.external, local.ext_subnets.dmz1, local.ext_subnets.dmz2, local.ext_subnets.dmz3, local.ext_subnets.dmz4]
  external_securitygroup_ids = [local.ext_security_groups.external, local.ext_security_groups.dmz1, local.ext_security_groups.dmz2, local.ext_security_groups.dmz3, local.ext_security_groups.dmz4]
  internal_subnet_ids        = [local.int_subnets.internal]
  internal_securitygroup_ids = [local.int_security_groups.internal]
  custom_user_data           = local.f5_onboard_sslo
  sleep_time                 = "30s"
  tags                       = local.tags
}

############################ GWLB Target Group Attachment ############################

resource "aws_lb_target_group_attachment" "bigipSslO" {
  target_group_arn = aws_lb_target_group.bigipSslO.arn
  target_id        = local.ext_subnets.external.private_ip_primary
}
