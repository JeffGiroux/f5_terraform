# AWS Network Load Balancer

module "nlb" {
  source             = "terraform-aws-modules/alb/aws"
  name               = format("%s-nlb-%s", var.projectPrefix, random_id.buildSuffix.hex)
  load_balancer_type = "network"
  vpc_id             = var.vpcId
  subnets            = [var.extSubnetAz1, var.extSubnetAz2]

  target_groups = [
    {
      name_prefix      = "tg-"
      backend_protocol = "TCP"
      backend_port     = 80
      target_type      = "instance"
    }
  ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "TCP"
      target_group_index = 0
    }
  ]

  tags = {
    Name  = "${var.projectPrefix}-nlb-${random_id.buildSuffix.hex}"
    Owner = var.resourceOwner
  }
}
