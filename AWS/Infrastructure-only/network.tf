# Networking

############################ VPC ############################

# Create VPC, subnets, route tables, and IGW
module "aws_network" {
  source                  = "github.com/f5devcentral/f5-digital-customer-engagement-center//modules/aws/terraform/network/min?ref=v1.1.0"
  projectPrefix           = var.projectPrefix
  buildSuffix             = random_id.buildSuffix.hex
  resourceOwner           = var.resourceOwner
  map_public_ip_on_launch = true
}

# Retrieve AWS VPC info
data "aws_vpc" "main" {
  id = module.aws_network.vpcs["main"]
}

############################ Security Groups ############################

# Security Group - mgmt
resource "aws_security_group" "mgmt" {
  name   = format("%s-sg-mgmt-%s", var.projectPrefix, random_id.buildSuffix.hex)
  vpc_id = module.aws_network.vpcs["main"]

  ingress {
    from_port   = 22
    to_port     = 22
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
    Name  = format("%s-sg-mgmt-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}

# Security Group - external
resource "aws_security_group" "external" {
  name   = format("%s-sg-ext-%s", var.projectPrefix, random_id.buildSuffix.hex)
  vpc_id = module.aws_network.vpcs["main"]

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
  vpc_id = module.aws_network.vpcs["main"]

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
