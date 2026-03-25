output "keyvault_id" {
  value = azurerm_key_vault.main.id
}

output "keyvault_uri" {
  value = azurerm_key_vault.main.vault_uri
}