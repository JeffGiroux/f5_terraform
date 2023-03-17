# Network for Security VPC

############################ VPC ############################

# Create resources for Security VPC
module "securityVpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "3.19.0"
  name                 = format("%s-securityVpc-%s", var.projectPrefix, random_id.buildSuffix.hex)
  cidr                 = var.securityVpcCidr
  azs                  = [var.awsAz1, var.awsAz2]
  public_subnets       = var.securityExternalSubnets
  private_subnets      = var.securityInternalSubnets
  enable_dns_hostnames = true
  public_subnet_tags = {
    Name = format("%s-securityVpc-external-%s", var.projectPrefix, random_id.buildSuffix.hex)
  }
  public_route_table_tags = {
    Name = format("%s-securityVpc-externalRtb-%s", var.projectPrefix, random_id.buildSuffix.hex)
  }
  private_subnet_tags = {
    Name = format("%s-securityVpc-internal-%s", var.projectPrefix, random_id.buildSuffix.hex)
  }
  private_route_table_tags = {
    Name = format("%s-securityVpc-internalRtb-%s", var.projectPrefix, random_id.buildSuffix.hex)
  }
  tags = {
    Name  = format("%s-securityVpc-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}

############################ Subnets ############################

# Create subnets for management
resource "aws_subnet" "mgmtAz1" {
  vpc_id            = module.securityVpc.vpc_id
  availability_zone = var.awsAz1
  cidr_block        = var.securityMgmtSubnets[0]
  tags = {
    Name  = format("%s-securityVpc-mgmt-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}
resource "aws_subnet" "mgmtAz2" {
  vpc_id            = module.securityVpc.vpc_id
  availability_zone = var.awsAz2
  cidr_block        = var.securityMgmtSubnets[1]
  tags = {
    Name  = format("%s-securityVpc-mgmt-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}

# Create subnets for dmz1
resource "aws_subnet" "dmz1Az1" {
  vpc_id            = module.securityVpc.vpc_id
  availability_zone = var.awsAz1
  cidr_block        = var.securityDmz1Subnets[0]
  tags = {
    Name  = format("%s-securityVpc-dmz1-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}
resource "aws_subnet" "dmz1Az2" {
  vpc_id            = module.securityVpc.vpc_id
  availability_zone = var.awsAz2
  cidr_block        = var.securityDmz1Subnets[1]
  tags = {
    Name  = format("%s-securityVpc-dmz1-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}

# Create subnets for dmz2
resource "aws_subnet" "dmz2Az1" {
  vpc_id            = module.securityVpc.vpc_id
  availability_zone = var.awsAz1
  cidr_block        = var.securityDmz2Subnets[0]
  tags = {
    Name  = format("%s-securityVpc-dmz2-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}
resource "aws_subnet" "dmz2Az2" {
  vpc_id            = module.securityVpc.vpc_id
  availability_zone = var.awsAz2
  cidr_block        = var.securityDmz2Subnets[1]
  tags = {
    Name  = format("%s-securityVpc-dmz2-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}

# Create subnets for dmz3
resource "aws_subnet" "dmz3Az1" {
  vpc_id            = module.securityVpc.vpc_id
  availability_zone = var.awsAz1
  cidr_block        = var.securityDmz3Subnets[0]
  tags = {
    Name  = format("%s-securityVpc-dmz3-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}
resource "aws_subnet" "dmz3Az2" {
  vpc_id            = module.securityVpc.vpc_id
  availability_zone = var.awsAz2
  cidr_block        = var.securityDmz3Subnets[1]
  tags = {
    Name  = format("%s-securityVpc-dmz3-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}

# Create subnets for dmz4
resource "aws_subnet" "dmz4Az1" {
  vpc_id            = module.securityVpc.vpc_id
  availability_zone = var.awsAz1
  cidr_block        = var.securityDmz4Subnets[0]
  tags = {
    Name  = format("%s-securityVpc-dmz4-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}
resource "aws_subnet" "dmz4Az2" {
  vpc_id            = module.securityVpc.vpc_id
  availability_zone = var.awsAz2
  cidr_block        = var.securityDmz4Subnets[1]
  tags = {
    Name  = format("%s-securityVpc-dmz4-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}

############################ Route Tables ############################

# Create routes for dmz1
resource "aws_route_table" "dmz1Az1" {
  vpc_id = module.securityVpc.vpc_id
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = module.bigipSslO.bigip_nic_ids["external_private"][0]
  }
  # route {
  #   cidr_block           = var.securityExternalSubnets[0]
  #   network_interface_id = aws_network_interface.inspection1["dmz1"].id
  # }
  tags = {
    Name  = format("%s-securityVpc-dmz1-inspection1Rtb-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}
resource "aws_route_table" "dmz1Az2" {
  vpc_id = module.securityVpc.vpc_id
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = module.bigipSslO.bigip_nic_ids["external_private"][0]
  }
  # route {
  #   cidr_block           = var.securityExternalSubnets[0]
  #   network_interface_id = aws_network_interface.inspection1["dmz1"].id
  # }
  tags = {
    Name  = format("%s-securityVpc-dmz1-inspection1Rtb-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}

# Create routes for dmz2
resource "aws_route_table" "dmz2Az1" {
  vpc_id = module.securityVpc.vpc_id
  # route {
  #   cidr_block           = "0.0.0.0/0"
  #   network_interface_id = aws_network_interface.inspection1["dmz2"].id
  # }
  route {
    cidr_block           = var.securityExternalSubnets[0]
    network_interface_id = module.bigipSslO.bigip_nic_ids["external_private"][1]
  }
  tags = {
    Name  = format("%s-securityVpc-dmz2-inspection1Rtb-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}
resource "aws_route_table" "dmz2Az2" {
  vpc_id = module.securityVpc.vpc_id
  # route {
  #   cidr_block           = "0.0.0.0/0"
  #   network_interface_id = aws_network_interface.inspection1["dmz2"].id
  # }
  route {
    cidr_block           = var.securityExternalSubnets[0]
    network_interface_id = module.bigipSslO.bigip_nic_ids["external_private"][1]
  }
  tags = {
    Name  = format("%s-securityVpc-dmz2-inspection1Rtb-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}

# Create routes for dmz3
resource "aws_route_table" "dmz3Az1" {
  vpc_id = module.securityVpc.vpc_id
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = module.bigipSslO.bigip_nic_ids["external_private"][2]
  }
  #   route {
  #     cidr_block           = var.securityExternalSubnets[0]
  #     network_interface_id = aws_network_interface.inspection2["dmz3"].id
  #   }
  tags = {
    Name  = format("%s-securityVpc-dmz3-inspection2Rtb-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}
resource "aws_route_table" "dmz3Az2" {
  vpc_id = module.securityVpc.vpc_id
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = module.bigipSslO.bigip_nic_ids["external_private"][2]
  }
  #   route {
  #     cidr_block           = var.securityExternalSubnets[0]
  #     network_interface_id = aws_network_interface.inspection2["dmz3"].id
  #   }
  tags = {
    Name  = format("%s-securityVpc-dmz3-inspection2Rtb-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}

# Create routes for dmz4
resource "aws_route_table" "dmz4Az1" {
  vpc_id = module.securityVpc.vpc_id
  #   route {
  #     cidr_block           = "0.0.0.0/0"
  #     network_interface_id = aws_network_interface.inspection2["dmz4"].id
  #   }
  route {
    cidr_block           = var.securityExternalSubnets[0]
    network_interface_id = module.bigipSslO.bigip_nic_ids["external_private"][3]
  }
  tags = {
    Name  = format("%s-securityVpc-dmz4-inspection2Rtb-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}
resource "aws_route_table" "dmz4Az2" {
  vpc_id = module.securityVpc.vpc_id
  #   route {
  #     cidr_block           = "0.0.0.0/0"
  #     network_interface_id = aws_network_interface.inspection2["dmz4"].id
  #   }
  route {
    cidr_block           = var.securityExternalSubnets[0]
    network_interface_id = module.bigipSslO.bigip_nic_ids["external_private"][3]
  }
  tags = {
    Name  = format("%s-securityVpc-dmz4-inspection2Rtb-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}

############################ Route Table Association ############################

# Associate route table with mgmt
resource "aws_route_table_association" "mgmtAz1" {
  subnet_id      = aws_subnet.mgmtAz1.id
  route_table_id = module.securityVpc.public_route_table_ids[0]
}
resource "aws_route_table_association" "mgmtAz2" {
  subnet_id      = aws_subnet.mgmtAz2.id
  route_table_id = module.securityVpc.public_route_table_ids[0]
}

# Associate route table with dmz1
resource "aws_route_table_association" "dmz1Az1" {
  subnet_id      = aws_subnet.dmz1Az1.id
  route_table_id = aws_route_table.dmz1Az1.id
}
resource "aws_route_table_association" "dmz1Az2" {
  subnet_id      = aws_subnet.dmz1Az2.id
  route_table_id = aws_route_table.dmz1Az2.id
}

# Associate route table with dmz2
resource "aws_route_table_association" "dmz2Az1" {
  subnet_id      = aws_subnet.dmz2Az1.id
  route_table_id = aws_route_table.dmz2Az1.id
}
resource "aws_route_table_association" "dmz2Az2" {
  subnet_id      = aws_subnet.dmz2Az2.id
  route_table_id = aws_route_table.dmz2Az2.id
}

# Associate route table with dmz3
resource "aws_route_table_association" "dmz3Az1" {
  subnet_id      = aws_subnet.dmz3Az1.id
  route_table_id = aws_route_table.dmz3Az1.id
}
resource "aws_route_table_association" "dmz3Az2" {
  subnet_id      = aws_subnet.dmz3Az2.id
  route_table_id = aws_route_table.dmz3Az2.id
}

# Associate route table with dmz4
resource "aws_route_table_association" "dmz4Az1" {
  subnet_id      = aws_subnet.dmz4Az1.id
  route_table_id = aws_route_table.dmz4Az1.id
}
resource "aws_route_table_association" "dmz4Az2" {
  subnet_id      = aws_subnet.dmz4Az2.id
  route_table_id = aws_route_table.dmz4Az2.id
}

############################ Security Groups ############################

# Security Group - mgmt
resource "aws_security_group" "management" {
  name   = format("%s-sg-management-%s", var.projectPrefix, random_id.buildSuffix.hex)
  vpc_id = module.securityVpc.vpc_id

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
    Name  = format("%s-sg-management-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}

# Security Group - external
resource "aws_security_group" "external" {
  name   = format("%s-sg-external-%s", var.projectPrefix, random_id.buildSuffix.hex)
  vpc_id = module.securityVpc.vpc_id

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
    from_port   = 6081
    to_port     = 6081
    protocol    = "udp"
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
    Name  = format("%s-sg-external-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}

# Security Group - internal
resource "aws_security_group" "internal" {
  name   = format("%s-sg-internal-%s", var.projectPrefix, random_id.buildSuffix.hex)
  vpc_id = module.securityVpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.securityVpc.vpc_cidr_block]
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
    Name  = format("%s-sg-internal-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}

# Security Group - inspection zone
resource "aws_security_group" "inspectionZone" {
  name   = format("%s-sg-inspectionZone-%s", var.projectPrefix, random_id.buildSuffix.hex)
  vpc_id = module.securityVpc.vpc_id

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
    Name  = format("%s-sg-inspectionZone-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}
