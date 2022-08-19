# Outputs

output "ALB_app1_pip" {
  description = "Public VIP IP for application"
  value       = azurerm_public_ip.lbpip.ip_address
}
output "HTTP_Link" {
  description = "Public VIP URL for application"
  value       = "http://${azurerm_public_ip.lbpip.ip_address}"
}
