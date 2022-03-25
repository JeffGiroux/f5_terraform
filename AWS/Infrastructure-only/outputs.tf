# Outputs

output "extSubnetAz1" {
  description = "ID of External subnet AZ1"
  value       = module.vpc.public_subnets[0]
}
output "extSubnetAz2" {
  description = "ID of External subnet AZ2"
  value       = module.vpc.public_subnets[1]
}
output "intSubnetAz1" {
  description = "ID of Internal subnet AZ1"
  value       = module.vpc.intra_subnets[0]
}
output "intSubnetAz2" {
  description = "ID of Internal subnet AZ2"
  value       = module.vpc.intra_subnets[1]
}
output "mgmtSubnetAz1" {
  description = "ID of Management subnet AZ1"
  value       = aws_subnet.mgmtAz1.id
}
output "mgmtSubnetAz2" {
  description = "ID of Management subnet AZ2"
  value       = aws_subnet.mgmtAz2.id
}
output "extNsg" {
  description = "ID of External security group"
  value       = aws_security_group.external.id
}
output "intNsg" {
  description = "ID of Internal security group"
  value       = aws_security_group.internal.id
}
output "mgmtNsg" {
  description = "ID of Management security group"
  value       = aws_security_group.mgmt.id
}
output "vpcId" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}
