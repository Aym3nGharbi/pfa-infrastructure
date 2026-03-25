output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "subnet_firewall_id" {
  value = azurerm_subnet.firewall.id
}

output "web_route_table_name" {
  value = azurerm_route_table.web.name
}

# output "subnet_firewall_mgmt_id" {
#   value = azurerm_subnet.firewall_mgmt.id
# }

output "subnet_gateway_id" {
  value = azurerm_subnet.gateway.id
}

output "subnet_appgateway_id" {
  value = azurerm_subnet.appgateway.id
}

output "subnet_web_id" {
  value = azurerm_subnet.web.id
}

output "subnet_data_id" {
  value = azurerm_subnet.data.id
}

output "web_nsg_id" {
  value = azurerm_network_security_group.web.id
}