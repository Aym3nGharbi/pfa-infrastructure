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