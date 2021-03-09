# Outputs

output "subnets_public" {
  value = [module.aws_network.subnetsAz2["public"], module.aws_network.subnetsAz1["public"]]
}

output "subnets_private" {
  value = [module.aws_network.subnetsAz2["private"], module.aws_network.subnetsAz1["private"]]
}

output "subnets_mgmt" {
  value = [module.aws_network.subnetsAz2["mgmt"], module.aws_network.subnetsAz1["mgmt"]]
}

output "vpc_id" {
  value = module.aws_network.vpcs["main"]
}