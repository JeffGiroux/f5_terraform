# Outputs

output "sslo_management" {
  description = "f5vm01 management private IP address"
  value       = module.bigipSslO.private_addresses["mgmt_private"]["private_ip"][0]
}
output "sslo_management_public_ip" {
  description = "f5vm01 management public IP address"
  value       = module.bigipSslO.mgmtPublicIP
}
output "sslo_management_public_dns" {
  description = "f5vm01 management public DNS"
  value       = module.bigipSslO.mgmtPublicDNS
}
output "sslo_external" {
  description = "f5vm01 external primary IP address (self IP)"
  value       = local.ext_subnets.external.private_ip_primary
}
output "sslo_internal" {
  description = "f5vm01 internal primary IP address"
  value       = module.bigipSslO.private_addresses["internal_private"]["private_ip"][0]
}
output "sslo_dmz1" {
  description = "f5vm01 dmz1 primary IP address (self IP)"
  value       = local.ext_subnets.dmz1.private_ip_primary
}
output "sslo_dmz2" {
  description = "f5vm01 dmz2 primary IP address (self IP)"
  value       = local.ext_subnets.dmz2.private_ip_primary
}
output "sslo_dmz3" {
  description = "f5vm01 dmz3 primary IP address (self IP)"
  value       = local.ext_subnets.dmz3.private_ip_primary
}
output "sslo_dmz4" {
  description = "f5vm01 dmz4 primary IP address (self IP)"
  value       = local.ext_subnets.dmz4.private_ip_primary
}
output "sslo_vip" {
  description = "Public IP for the BIG-IP listener (VIP)"
  value       = module.bigipSslO.public_addresses["external_secondary_public"][0]
}
# output "sslo_external_nic_id" {
#   description = "f5vm01 external network interface ID"
#   value       = module.bigipSslO.nic_ids["public_private"][0]
# }
# output "sslo_internal_nic_id" {
#   description = "f5vm01 internal network interface ID"
#   value       = module.bigipSslO.nic_ids["internal_private"][0]
# }
# output "sslo_dmz1_nic_id" {
#   description = "f5vm01 dmz1 network interface ID"
#   value       = module.bigipSslO.nic_ids["external_private"][0]
# }
# output "sslo_dmz2_nic_id" {
#   description = "f5vm01 dmz2 network interface ID"
#   value       = module.bigipSslO.nic_ids["external_private"][1]
# }
# output "sslo_dmz3_nic_id" {
#   description = "f5vm01 dmz3 network interface ID"
#   value       = module.bigipSslO.nic_ids["external_private"][2]
# }
# output "sslo_dmz4_nic_id" {
#   description = "f5vm01 dmz4 network interface ID"
#   value       = module.bigipSslO.nic_ids["external_private"][3]
# }
output "webapp_private_ip" {
  description = "Private IP address of the web app server"
  value       = module.webapp.private_ip
}
output "webapp_public_ip" {
  description = "Public IP address of the web app server"
  value       = module.webapp.public_ip
}
# output "inspection_service_ip_1" {
#   description = "Private IP address of the Inspection Service #1"
#   value       = aws_network_interface.inspection1["dmz1"].private_ip
# }
