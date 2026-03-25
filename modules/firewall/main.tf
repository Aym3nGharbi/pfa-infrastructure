# Public IP for Azure Firewall
resource "azurerm_public_ip" "firewall" {
  name                = "${var.prefix}-firewall-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Azure Firewall (Standard SKU, no forced tunneling)
resource "azurerm_firewall" "main" {
  name                = "${var.prefix}-firewall"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  tags                = var.tags

  ip_configuration {
    name                 = "firewall-ip-config"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

  # Threat intelligence (Alert mode for PFA)
  threat_intel_mode = "Alert"
}

# DNAT Rules for incoming traffic (HTTP/HTTPS to App Gateway)
resource "azurerm_firewall_nat_rule_collection" "dnat" {
  name                = "dnat-rules"
  azure_firewall_name = azurerm_firewall.main.name
  resource_group_name = var.resource_group_name
  priority            = 100
  action              = "Dnat"

  rule {
    name = "http-to-appgateway"
    protocols = ["TCP"]
    source_addresses = ["*"]
    destination_addresses = [azurerm_public_ip.firewall.ip_address]
    destination_ports = ["80"]
    translated_address = var.appgateway_private_ip
    translated_port = "80"
  }

  rule {
    name = "https-to-appgateway"
    protocols = ["TCP"]
    source_addresses = ["*"]
    destination_addresses = [azurerm_public_ip.firewall.ip_address]
    destination_ports = ["443"]
    translated_address = var.appgateway_private_ip
    translated_port = "443"
  }
}

# Network Rules for outbound traffic
resource "azurerm_firewall_network_rule_collection" "network" {
  name                = "network-rules"
  azure_firewall_name = azurerm_firewall.main.name
  resource_group_name = var.resource_group_name
  priority            = 200
  action              = "Allow"

  rule {
    name = "allow-vm-to-internet"
    protocols = ["TCP", "UDP"]
    source_addresses = [var.vm_subnet_cidr]
    destination_addresses = ["*"]
    destination_ports = ["*"]
  }

  rule {
    name = "allow-dns"
    protocols = ["UDP"]
    source_addresses = ["*"]
    destination_addresses = ["*"]
    destination_ports = ["53"]
  }
}

# Application Rules for FQDN-based filtering
resource "azurerm_firewall_application_rule_collection" "application" {
  name                = "application-rules"
  azure_firewall_name = azurerm_firewall.main.name
  resource_group_name = var.resource_group_name
  priority            = 300
  action              = "Allow"

  rule {
    name = "allow-github"
    source_addresses = [var.vm_subnet_cidr]
    target_fqdns = ["github.com", "*.github.com", "api.github.com"]
    protocol {
      port = "443"
      type = "Https"
    }
  }

  rule {
    name = "allow-microsoft"
    source_addresses = [var.vm_subnet_cidr]
    target_fqdns = ["*.microsoft.com", "*.azure.com", "*.windows.net"]
    protocol {
      port = "443"
      type = "Https"
    }
  }

  rule {
    name = "allow-ubuntu"
    source_addresses = [var.vm_subnet_cidr]
    target_fqdns = ["*.ubuntu.com", "*.canonical.com"]
    protocol {
      port = "80"
      type = "Http"
    }
    protocol {
      port = "443"
      type = "Https"
    }
  }
}