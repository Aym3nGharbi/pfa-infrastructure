# Public IP for VPN Gateway
resource "azurerm_public_ip" "vpn" {
  name                = "${var.prefix}-vpn-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# VPN Gateway — Basic tier, Point-to-Site
resource "azurerm_virtual_network_gateway" "vpn" {
  name                = "${var.prefix}-vpn-gateway"
  location            = var.location
  resource_group_name = var.resource_group_name
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"
  active_active       = false
  enable_bgp          = false
  tags                = var.tags

  ip_configuration {
    name                          = "vpn-ip-config"
    public_ip_address_id          = azurerm_public_ip.vpn.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.subnet_gateway_id
  }

  vpn_client_configuration {
    address_space = [var.vpn_client_address_pool]

    vpn_client_protocols = ["OpenVPN"]

    vpn_auth_types = ["AAD"]

    aad_tenant   = "https://login.microsoftonline.com/${data.azurerm_client_config.current.tenant_id}/"
    aad_audience = "41b23e61-6c1e-4545-b367-cd054e0ed4b4"
    aad_issuer   = "https://sts.windows.net/${data.azurerm_client_config.current.tenant_id}/"
  }
}

data "azurerm_client_config" "current" {}