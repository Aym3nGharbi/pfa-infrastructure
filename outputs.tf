output "resource_group_name" {
  value = azurerm_resource_group.pfa.name
}

output "vm_private_ip" {
  value = module.vm.vm_private_ip
}

output "vm_name" {
  value = module.vm.vm_name
}

output "appgateway_public_ip" {
  value = module.appgateway.appgateway_public_ip
}

# output "firewall_public_ip" {
#   value = module.firewall.firewall_public_ip
# }

# output "firewall_private_ip" {
#   value = module.firewall.firewall_private_ip
# }

output "vpn_public_ip" {
  value = module.vpn.vpn_public_ip
}

output "cosmosdb_endpoint" {
  value = module.cosmosdb.cosmosdb_endpoint
}

output "keyvault_uri" {
  value = module.keyvault.keyvault_uri
}

output "terraform_apply_command" {
  description = "Command to apply infrastructure"
  value       = "terraform apply -auto-approve"
}

output "terraform_destroy_command" {
  description = "Command to destroy infrastructure (save money)"
  value       = "terraform destroy -auto-approve"
}