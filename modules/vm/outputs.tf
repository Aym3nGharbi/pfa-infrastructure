output "vm_private_ip" {
  value = azurerm_network_interface.vm.private_ip_address
}

output "vm_id" {
  value = azurerm_linux_virtual_machine.vm.id
}

output "vm_identity_principal_id" {
  description = "System assigned identity — used to give VM access to Key Vault"
  value       = azurerm_linux_virtual_machine.vm.identity[0].principal_id
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.vm.name
}