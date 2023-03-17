# BIG-IP

############################ Locals ############################

locals {
  # Retrieve all BIG-IP secondary IPs
  vm01_ext_ips = {
    0 = {
      ip = element(flatten(module.bigip.private_addresses["public_private"]["private_ips"][0]), 0)
    }
    1 = {
      ip = element(flatten(module.bigip.private_addresses["public_private"]["private_ips"][0]), 1)
    }
  }
  # Determine BIG-IP secondary IPs to be used for VIP
  vm01_vip_ips = {
    app1 = {
      ip = module.bigip.private_addresses["public_private"]["private_ip"][0] != local.vm01_ext_ips.0.ip ? local.vm01_ext_ips.0.ip : local.vm01_ext_ips.1.ip
    }
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
  arn   = var.aws_secretmanager_secret_id
}

data "aws_secretsmanager_secret_version" "current" {
  count     = var.aws_secretmanager_auth ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.password[0].id
}

############################ AMI ############################

# Find BIG-IP AMI
data "aws_ami" "f5_ami" {
  most_recent = true
  owners      = ["aws-marketplace"]
  filter {
    name   = "name"
    values = [var.f5_ami_search_name]
  }
}

############################ Onboard Scripts ############################

# Setup Onboarding scripts
locals {
  f5_onboard1 = templatefile("${path.module}/f5_onboard.tmpl", {
    regKey                      = var.license1
    f5_username                 = var.f5_username
    f5_password                 = var.aws_secretmanager_auth ? "" : var.f5_password
    aws_secretmanager_auth      = var.aws_secretmanager_auth
    aws_secretmanager_secret_id = var.aws_secretmanager_auth ? data.aws_secretsmanager_secret_version.current[0].secret_id : ""
    INIT_URL                    = var.INIT_URL
    DO_URL                      = var.DO_URL
    AS3_URL                     = var.AS3_URL
    TS_URL                      = var.TS_URL
    FAST_URL                    = var.FAST_URL
    DO_VER                      = split("/", var.DO_URL)[7]
    AS3_VER                     = split("/", var.AS3_URL)[7]
    TS_VER                      = split("/", var.TS_URL)[7]
    FAST_VER                    = split("/", var.FAST_URL)[7]
    vpc_cidr_block              = data.aws_vpc.main.cidr_block
    dns_server                  = var.dns_server
    ntp_server                  = var.ntp_server
    timezone                    = var.timezone
    bigIqLicenseType            = var.bigIqLicenseType
    bigIqHost                   = var.bigIqHost
    bigIqPassword               = var.bigIqPassword
    bigIqUsername               = var.bigIqUsername
    bigIqLicensePool            = var.bigIqLicensePool
    bigIqSkuKeyword1            = var.bigIqSkuKeyword1
    bigIqSkuKeyword2            = var.bigIqSkuKeyword2
    bigIqUnitOfMeasure          = var.bigIqUnitOfMeasure
    bigIqHypervisor             = var.bigIqHypervisor
  })
}

############################ Compute ############################

# Create F5 BIG-IP VMs
module "bigip" {
  source                     = "F5Networks/bigip-module/aws"
  version                    = "1.1.11"
  prefix                     = format("%s-3nic", var.projectPrefix)
  ec2_instance_type          = var.ec2_instance_type
  ec2_key_name               = var.ec2_key_name
  f5_ami_search_name         = var.f5_ami_search_name
  f5_username                = var.f5_username
  aws_iam_instance_profile   = var.aws_iam_instance_profile == null ? aws_iam_instance_profile.bigip_profile[0].name : var.aws_iam_instance_profile
  mgmt_subnet_ids            = [{ "subnet_id" = var.mgmtSubnetAz1, "public_ip" = true, "private_ip_primary" = "" }]
  mgmt_securitygroup_ids     = [var.mgmtNsg]
  external_subnet_ids        = [{ "subnet_id" = var.extSubnetAz1, "public_ip" = true, "private_ip_primary" = "", "private_ip_secondary" = "" }]
  external_securitygroup_ids = [var.extNsg]
  internal_subnet_ids        = [{ "subnet_id" = var.intSubnetAz1, "public_ip" = false, "private_ip_primary" = "", "private_ip_secondary" = "" }]
  internal_securitygroup_ids = [var.intNsg]
  custom_user_data           = local.f5_onboard1
  sleep_time                 = "30s"
  tags                       = local.tags
}
