# Outputs

output "ALB_app1_pip" {
  description = "Public VIP IP for application"
  value       = azurerm_public_ip.lbpip.ip_address
}
output "HTTPS_Link" {
  description = "Public VIP URL for application"
  value       = "https://${azurerm_public_ip.lbpip.ip_address}"
}
