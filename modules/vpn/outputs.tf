output "vpn_gateway_id" {
  value = azurerm_virtual_network_gateway.vpn.id
}

output "vpn_public_ip" {
  value = azurerm_public_ip.vpn.ip_address
}

output "vpn_client_address_pool" {
  value = var.vpn_client_address_pool
}