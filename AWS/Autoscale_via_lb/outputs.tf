# Outputs

#output "public_vip" { value = module.nlb.this_lb_dns_name }
#output "public_vip_url" { value = "https://${module.nlb.this_lb_dns_name}" }
output "asg_name" { value = aws_autoscaling_group.bigip-asg.id }
