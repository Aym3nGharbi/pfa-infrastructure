output "appgateway_public_ip" {
  value = azurerm_public_ip.appgateway.ip_address
}

output "appgateway_private_ip" {
  value = "10.0.2.10"  # Static private IP
}

output "appgateway_id" {
  value = azurerm_application_gateway.main.id
}

output "waf_policy_id" {
  value = azurerm_web_application_firewall_policy.main.id
}

output "backend_pool_name" {
  value = "web-backend-pool"
}