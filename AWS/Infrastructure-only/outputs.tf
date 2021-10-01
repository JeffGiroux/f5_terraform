# Outputs

output "subnets_external_Az1" {
  description = "ID of External subnet AZ1"
  value       = module.aws_network.subnetsAz1["public"]
}
output "subnets_external_Az2" {
  description = "ID of External subnet AZ2"
  value       = module.aws_network.subnetsAz2["public"]
}
output "subnets_internal_Az1" {
  description = "ID of Internal subnet AZ1"
  value       = module.aws_network.subnetsAz1["private"]
}
output "subnets_internal_Az2" {
  description = "ID of Internal subnet AZ2"
  value       = module.aws_network.subnetsAz2["private"]
}
output "subnets_mgmt_Az1" {
  description = "ID of Management subnet AZ1"
  value       = module.aws_network.subnetsAz1["mgmt"]
}
output "subnets_mgmt_Az2" {
  description = "ID of Management subnet AZ1"
  value       = module.aws_network.subnetsAz2["mgmt"]
}
output "security_group_external" {
  description = "ID of External security group"
  value       = aws_security_group.external.id
}
output "security_group_internal" {
  description = "ID of Internal security group"
  value       = aws_security_group.internal.id
}
output "security_group_mgmt" {
  description = "ID of Management security group"
  value       = aws_security_group.mgmt.id
}
output "vpc_id" {
  description = "VPC ID"
  value       = module.aws_network.vpcs["main"]
}
