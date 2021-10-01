# Outputs

output "public_vip" {
  description = "AWS NLB DNS name"
  value       = module.nlb.lb_dns_name
}
output "public_vip_url" {
  description = "HTTP URL link for AWS NLB DNS name"
  value       = "http://${module.nlb.lb_dns_name}"
}
output "asg_name" {
  description = "AWS autoscaling group name of BIG-IP devices"
  value       = aws_autoscaling_group.bigip-asg.id
}
