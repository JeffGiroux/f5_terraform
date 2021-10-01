# BIG-IP

# Setup Onboarding scripts
locals {
  f5_onboard = templatefile("${path.module}/f5_onboard.tmpl", {
    f5_username = var.f5_username
    f5_password = var.f5_password
  })
  vm01_do_json = templatefile("${path.module}/do.json", {
    ntp_server         = var.ntp_server
    timezone           = var.timezone
    bigIqLicenseType   = var.bigIqLicenseType
    bigIqHost          = var.bigIqHost
    bigIqUsername      = var.bigIqUsername
    bigIqLicensePool   = var.bigIqLicensePool
    bigIqSkuKeyword1   = var.bigIqSkuKeyword1
    bigIqSkuKeyword2   = var.bigIqSkuKeyword2
    bigIqUnitOfMeasure = var.bigIqUnitOfMeasure
    bigIqHypervisor    = var.bigIqHypervisor
  })
}

# Create security groups for EC2 instances
module "external-security-group" {
  source      = "terraform-aws-modules/security-group/aws"
  name        = format("%s-external-sg-%s", var.projectPrefix, random_id.buildSuffix.hex)
  description = "Security group for BIG-IP"
  vpc_id      = var.vpcId

  ingress_cidr_blocks = var.allowedIps
  ingress_rules       = ["http-80-tcp", "https-443-tcp", "https-8443-tcp", "ssh-tcp"]

  # Allow ec2 instances outbound Internet connectivity
  egress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules       = ["all-all"]

  tags = {
    Name  = "${var.projectPrefix}-external-sg-${random_id.buildSuffix.hex}"
    Owner = var.resourceOwner
  }
}

# Find BIG-IP AMI
data "aws_ami" "f5_ami" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "name"
    values = [var.f5_ami_search_name]
  }
}

# Create BIG-IP launch template
resource "aws_launch_template" "bigip-lt" {
  name          = format("%s-bigip-lt-%s", var.projectPrefix, random_id.buildSuffix.hex)
  image_id      = data.aws_ami.f5_ami.id
  instance_type = var.ec2_instance_type
  key_name      = var.f5_ssh_publickey
  user_data     = base64encode(local.f5_onboard)

  network_interfaces {
    device_index          = 0
    description           = "eth0"
    delete_on_termination = true
    security_groups       = [module.external-security-group.security_group_id]
  }
  network_interfaces {
    device_index          = 1
    description           = "eth1"
    delete_on_termination = true
    security_groups       = [module.external-security-group.security_group_id]
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
  #target_group_arns   = module.nlb.target_group_arns

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
