# BIG-IP

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
  f5_onboard = templatefile("${path.module}/f5_onboard.tmpl", {
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

############################ Autoscaling ############################

# Create BIG-IP launch template
resource "aws_launch_template" "bigip-lt" {
  name          = format("%s-bigip-lt-%s", var.projectPrefix, random_id.buildSuffix.hex)
  image_id      = data.aws_ami.f5_ami.id
  instance_type = var.ec2_instance_type
  key_name      = var.ec2_key_name
  user_data     = base64encode(local.f5_onboard)

  network_interfaces {
    device_index                = 0
    description                 = "eth0"
    delete_on_termination       = true
    security_groups             = [var.extNsg]
    associate_public_ip_address = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name  = "${var.projectPrefix}-bigip-lt-${random_id.buildSuffix.hex}"
      Owner = var.resourceOwner
    }
  }
}

# Create BIG-IP autoscaling group
resource "aws_autoscaling_group" "bigip-asg" {
  name                = format("%s-bigip-asg-%s", var.projectPrefix, random_id.buildSuffix.hex)
  desired_capacity    = var.asg_desired_capacity
  max_size            = var.asg_max_size
  min_size            = var.asg_min_size
  health_check_type   = "EC2"
  vpc_zone_identifier = [var.extSubnetAz1, var.extSubnetAz2]
  target_group_arns   = module.nlb.target_group_arns

  launch_template {
    id      = aws_launch_template.bigip-lt.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    # preferences {
    #   min_healthy_percentage = 50
    # }
    # triggers = ["tag"]
  }

  tag {
    key                 = "Name"
    value               = "${var.projectPrefix}-bigip-${random_id.buildSuffix.hex}"
    propagate_at_launch = true
  }
  tag {
    key                 = "Owner"
    value               = var.resourceOwner
    propagate_at_launch = true
  }
}
