# Outputs

output "subnets_external_az1" {
  description = "ID of External subnet AZ1"
  value       = module.vpc.public_subnets[0]
}
output "subnets_external_az2" {
  description = "ID of External subnet AZ2"
  value       = module.vpc.public_subnets[1]
}
output "subnets_internal_az1" {
  description = "ID of Internal subnet AZ1"
  value       = module.vpc.intra_subnets[0]
}
output "subnets_internal_az2" {
  description = "ID of Internal subnet AZ2"
  value       = module.vpc.intra_subnets[1]
}
output "subnets_mgmt_az1" {
  description = "ID of Management subnet AZ1"
  value       = aws_subnet.mgmtAz1.id
}
output "subnets_mgmt_az2" {
  description = "ID of Management subnet AZ2"
  value       = aws_subnet.mgmtAz2.id
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
