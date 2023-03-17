# Web App

############################ AMI ############################

# Find WebApp (Wordpress) AMI
data "aws_ami" "webapp" {
  most_recent = true
  owners      = ["aws-marketplace"]
  filter {
    name   = "name"
    values = [var.webapp_ami_search_name]
  }
}

############################ Compute ############################

module "webapp" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "4.3.0"
  ami                    = data.aws_ami.webapp.id
  instance_type          = "t3.small"
  key_name               = aws_key_pair.bigip.key_name
  private_ip             = cidrhost(var.applicationPrivateSubnets[0], 200)
  vpc_security_group_ids = [aws_security_group.webapp.id]
  subnet_id              = module.applicationVpc.private_subnets[0]
  tags = {
    Name  = format("%s-webapp-%s", var.projectPrefix, random_id.buildSuffix.hex)
    Owner = var.resourceOwner
  }

  associate_public_ip_address = true
}

############################ NLB Target Group Attachment ############################

# resource "aws_lb_target_group_attachment" "webapp" {
#   target_group_arn = module.nlb.target_group_arns[0]
#   target_id        = module.webapp.id
#   port             = 80
# }
