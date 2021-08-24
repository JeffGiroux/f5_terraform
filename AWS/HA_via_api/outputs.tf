# Outputs

output "storage_bucket" { value = aws_s3_bucket.main.arn }
output "public_vip_pip" { value = aws_eip.vip-pip.public_ip }

output "f5vm01_mgmt_private_ip" { value = aws_network_interface.vm01-mgmt-nic.private_ip }
output "f5vm01_mgmt_public_ip" { value = aws_eip.vm01-mgmt-pip.public_ip }
output "f5vm01_ext_private_ip" { value = aws_network_interface.vm01-ext-nic.private_ip }
output "f5vm01_ext_secondary_ip" { value = local.vm01_vip_ips.app1.ip }
output "f5vm01_int_private_ip" { value = aws_network_interface.vm01-int-nic.private_ip }

output "f5vm02_mgmt_private_ip" { value = aws_network_interface.vm02-mgmt-nic.private_ip }
output "f5vm02_mgmt_public_ip" { value = aws_eip.vm02-mgmt-pip.public_ip }
output "f5vm02_ext_private_ip" { value = aws_network_interface.vm02-ext-nic.private_ip }
output "f5vm02_ext_secondary_ip" { value = local.vm02_vip_ips.app1.ip }
output "f5vm02_int_private_ip" { value = aws_network_interface.vm02-int-nic.private_ip }
