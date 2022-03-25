# Outputs

output "subnets_external" {
  description = "ID of External subnets"
  value       = module.vpc.public_subnets
}
output "subnets_internal" {
  description = "ID of Internal subnets"
  value       = module.vpc.intra_subnets
}
output "subnets_mgmt" {
  description = "ID of Internal subnets"
  value       = module.vpc.private_subnets
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
  value       = module.vpc.vpc_id
}
