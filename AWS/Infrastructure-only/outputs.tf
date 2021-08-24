# Outputs

output "subnets_external_Az1" { value = module.aws_network.subnetsAz1["public"] }
output "subnets_external_Az2" { value = module.aws_network.subnetsAz2["public"] }
output "subnets_internal_Az1" { value = module.aws_network.subnetsAz1["private"] }
output "subnets_internal_Az2" { value = module.aws_network.subnetsAz2["private"] }
output "subnets_mgmt_Az1" { value = module.aws_network.subnetsAz1["mgmt"] }
output "subnets_mgmt_Az2" { value = module.aws_network.subnetsAz2["mgmt"] }
output "security_group_external" { value = aws_security_group.external.id }
output "security_group_internal" { value = aws_security_group.internal.id }
output "security_group_mgmt" { value = aws_security_group.mgmt.id }
output "vpc_id" { value = module.aws_network.vpcs["main"] }