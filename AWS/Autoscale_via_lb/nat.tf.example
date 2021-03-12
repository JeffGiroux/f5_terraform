# AWS NAT Gateway

# Create Elastic IP
resource "aws_eip" "nat" {
  vpc = true

  tags = {
    Name  = "${var.projectPrefix}-nat-pip-${random_id.buildSuffix.hex}"
    Owner = var.resourceOwner
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.mgmtSubnetAz1

  tags = {
    Name  = "${var.projectPrefix}-nat-${random_id.buildSuffix.hex}"
    Owner = var.resourceOwner
  }
}
