resource "azurerm_cosmosdb_account" "main" {
  name                = "${var.prefix}-cosmosdb"
  location            = var.location
  resource_group_name = var.resource_group_name

  offer_type = "Standard"
  kind       = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.location
    failover_priority = 0
  }

  # 🔐 Restrict access to VNet only
  is_virtual_network_filter_enabled = true

  virtual_network_rule {
    id = var.subnet_data_id
  }

  public_network_access_enabled = false

  tags = var.tags
}