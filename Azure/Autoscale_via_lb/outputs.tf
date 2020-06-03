# Outputs

output "ALB_app1_pip" { value = azurerm_public_ip.lbpip.ip_address }
output "HTTPS_Link" { value = "https://${azurerm_public_ip.lbpip.ip_address}" }
