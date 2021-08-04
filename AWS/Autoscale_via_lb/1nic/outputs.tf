# Outputs

output "public_vip" { value = module.nlb.lb_dns_name }
output "public_vip_url" { value = "http://${module.nlb.lb_dns_name}" }
output "asg_name" { value = aws_autoscaling_group.bigip-asg.id }
