# AWS Gateway Load Balancer

############################ GWLB ############################

# Create GWLB in Security VPC
resource "aws_lb" "gwlb" {
  name               = format("%s-gwlb-%s", var.projectPrefix, random_id.buildSuffix.hex)
  internal           = false
  load_balancer_type = "gateway"
  subnets            = module.securityVpc.public_subnets

  tags = {
    Name  = format("%s-gwlb-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}

############################ Target Group ############################

# Create target group for BIG-IP SSL Orchestrator devices
resource "aws_lb_target_group" "bigipSslO" {
  name        = format("%s-tg-%s", var.projectPrefix, random_id.buildSuffix.hex)
  port        = 6081
  protocol    = "GENEVE"
  target_type = "ip"
  vpc_id      = module.securityVpc.vpc_id

  health_check {
    protocol = "TCP"
    port     = 80
  }

  tags = {
    Name  = format("%s-tg-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}

############################ GWLB Listener ############################

resource "aws_lb_listener" "gwlb" {
  load_balancer_arn = aws_lb.gwlb.id

  default_action {
    target_group_arn = aws_lb_target_group.bigipSslO.id
    type             = "forward"
  }
}

############################ VPC Endpoints ############################

# Create GWLB endpoint service
resource "aws_vpc_endpoint_service" "gwlb" {
  acceptance_required        = false
  gateway_load_balancer_arns = [aws_lb.gwlb.arn]
  tags = {
    Name  = format("%s-gwlbe-svc-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}

# Create GWLB endpoints in Security VPC
resource "aws_vpc_endpoint" "securityGwlbeAz1" {
  service_name      = aws_vpc_endpoint_service.gwlb.service_name
  subnet_ids        = [module.securityVpc.public_subnets[0]]
  vpc_endpoint_type = "GatewayLoadBalancer"
  vpc_id            = module.securityVpc.vpc_id
  tags = {
    Name  = format("%s-securityGwlbeAz1-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}
resource "aws_vpc_endpoint" "securityGwlbeAz2" {
  service_name      = aws_vpc_endpoint_service.gwlb.service_name
  subnet_ids        = [module.securityVpc.public_subnets[1]]
  vpc_endpoint_type = "GatewayLoadBalancer"
  vpc_id            = module.securityVpc.vpc_id
  tags = {
    Name  = format("%s-securityGwlbeAz2-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}

# Create GWLB endpoints in Application VPC
resource "aws_vpc_endpoint" "applicationGwlbeAz1" {
  service_name      = aws_vpc_endpoint_service.gwlb.service_name
  subnet_ids        = [module.applicationVpc.public_subnets[0]]
  vpc_endpoint_type = "GatewayLoadBalancer"
  vpc_id            = module.applicationVpc.vpc_id
  tags = {
    Name  = format("%s-applicationGwlbeAz1-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}
resource "aws_vpc_endpoint" "applicationGwlbeAz2" {
  service_name      = aws_vpc_endpoint_service.gwlb.service_name
  subnet_ids        = [module.applicationVpc.public_subnets[1]]
  vpc_endpoint_type = "GatewayLoadBalancer"
  vpc_id            = module.applicationVpc.vpc_id
  tags = {
    Name  = format("%s-applicationGwlbeAz2-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }
}
