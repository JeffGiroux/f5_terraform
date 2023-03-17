# Network for Application VPC

############################ VPC ############################

# Create resources for Application VPC
module "applicationVpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "3.19.0"
  name                 = format("%s-applicationVpc-%s", var.projectPrefix, random_id.buildSuffix.hex)
  cidr                 = var.applicationVpcCidr
  azs                  = [var.awsAz1, var.awsAz2]
  public_subnets       = var.applicationGwlbeSubnets
  private_subnets      = var.applicationPrivateSubnets
  enable_dns_hostnames = true
  public_subnet_tags = {
    Name = format("%s-applicationVpc-gwlbe-%s", var.projectPrefix, random_id.buildSuffix.hex)
  }
  public_route_table_tags = {
    Name = format("%s-applicationVpc-gwlbeRtb-%s", var.projectPrefix, random_id.buildSuffix.hex)
  }
  private_subnet_tags = {
    Name = format("%s-applicationVpc-app-%s", var.projectPrefix, random_id.buildSuffix.hex)
  }
  private_route_table_tags = {
    Name = format("%s-applicationVpc-appRtb-%s", var.projectPrefix, random_id.buildSuffix.hex)
  }
  tags = {
    Name  = format("%s-applicationVpc-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}

############################ Route Tables ############################

# Create routes for internet gateway to app via GWLBe
resource "aws_route_table" "igwRtb" {
  vpc_id = module.applicationVpc.vpc_id
  route {
    cidr_block      = var.applicationPrivateSubnets[0]
    vpc_endpoint_id = aws_vpc_endpoint.applicationGwlbeAz1.id
  }
  route {
    cidr_block      = var.applicationPrivateSubnets[1]
    vpc_endpoint_id = aws_vpc_endpoint.applicationGwlbeAz2.id
  }
  tags = {
    Name  = format("%s-applicationVpc-igwRtb-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}

# Create default route for app servers via GWLBe
resource "aws_route" "fromAppAz1" {
  route_table_id         = module.applicationVpc.private_route_table_ids[0]
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = aws_vpc_endpoint.applicationGwlbeAz1.id
}
resource "aws_route" "fromAppAz2" {
  route_table_id         = module.applicationVpc.private_route_table_ids[1]
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = aws_vpc_endpoint.applicationGwlbeAz2.id
}

############################ Route Table Association ############################

# Associate route table with internet gateway
resource "aws_route_table_association" "igwRtb" {
  gateway_id     = module.applicationVpc.igw_id
  route_table_id = aws_route_table.igwRtb.id
}

############################ Security Groups ############################

# Security Group - webapp
resource "aws_security_group" "webapp" {
  name   = format("%s-sg-webapp-%s", var.projectPrefix, random_id.buildSuffix.hex)
  vpc_id = module.applicationVpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = format("%s-sg-webapp-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}
