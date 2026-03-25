output "firewall_private_ip" {
  description = "Private IP of Azure Firewall for UDR"
  value       = azurerm_firewall.main.ip_configuration[0].private_ip_address
}

output "firewall_public_ip" {
  description = "Public IP of Azure Firewall"
  value       = azurerm_public_ip.firewall.ip_address
}