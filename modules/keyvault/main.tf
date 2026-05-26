resource "azurerm_key_vault" "main" {
  name                = "${var.prefix}-kv"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = var.tenant_id

  sku_name = "standard"

  purge_protection_enabled   = true
  soft_delete_retention_days = 7

  tags = var.tags
}

# Access policy for VM
resource "azurerm_key_vault_access_policy" "vm" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = var.tenant_id
  object_id    = var.vm_principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

# Optional: import PFX into Key Vault as a secret for Application Gateway
resource "azurerm_key_vault_secret" "appgw_pfx" {
  count        = var.appgateway_pfx_path != "" ? 1 : 0
  name         = "${var.prefix}-appgw-pfx"
  value        = filebase64(var.appgateway_pfx_path)
  key_vault_id = azurerm_key_vault.main.id
  content_type = "application/x-pkcs12"
  tags         = var.tags
}

output "appgw_pfx_secret_id" {
  description = "ID of PFX secret imported into Key Vault (empty if none)"
  value       = length(azurerm_key_vault_secret.appgw_pfx) > 0 ? azurerm_key_vault_secret.appgw_pfx[0].id : ""
}