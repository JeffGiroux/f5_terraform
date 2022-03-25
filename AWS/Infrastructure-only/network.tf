############################ Locals ############################

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  awsAz1 = var.awsAz1 != null ? var.awsAz1 : data.aws_availability_zones.available.names[0]
  awsAz2 = var.awsAz2 != null ? var.awsAz2 : data.aws_availability_zones.available.names[1]
}

############################ VPC ############################

# Create VPC, subnets, route tables, and IGW
module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "~> 3.0"
  name                 = "${var.projectPrefix}-vpc-${random_id.buildSuffix.hex}"
  cidr                 = var.vpc_cidr
  azs                  = [local.awsAz1, local.awsAz2]
  public_subnets       = var.ext_address_prefixes
  private_subnets      = var.mgmt_address_prefixes
  intra_subnets        = var.int_address_prefixes
  enable_dns_hostnames = true
  enable_nat_gateway   = true
  tags = {
    resourceOwner = var.resourceOwner
    Name          = "${var.projectPrefix}-vpc-${random_id.buildSuffix.hex}"
  }
}

# Retrieve AWS VPC info
data "aws_vpc" "main" {
  id = module.vpc.vpc_id
}

############################ Security Groups ############################

# Security Group - mgmt
resource "aws_security_group" "mgmt" {
  name   = format("%s-sg-mgmt-%s", var.projectPrefix, random_id.buildSuffix.hex)
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.adminSrcAddr]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.adminSrcAddr]
  }
  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = [var.adminSrcAddr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = format("%s-sg-mgmt-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}

# Security Group - external
resource "aws_security_group" "external" {
  name   = format("%s-sg-ext-%s", var.projectPrefix, random_id.buildSuffix.hex)
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = format("%s-sg-ext-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner

  }
}

# Security Group - internal
resource "aws_security_group" "internal" {
  name   = format("%s-sg-int-%s", var.projectPrefix, random_id.buildSuffix.hex)
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = format("%s-sg-int-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner

  }
}
