# VNet
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_cidr]
  tags                = var.tags
}

# Subnets
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_cidrs.firewall]
}

# Subnet for Firewall Management (OBLIGATOIRE pour Basic SKU)
# resource "azurerm_subnet" "firewall_mgmt" {
#   name                 = "AzureFirewallManagementSubnet"
#   resource_group_name  = var.resource_group_name
#   virtual_network_name = azurerm_virtual_network.vnet.name
#   address_prefixes     = [var.subnet_cidrs.firewall_mgmt]
# }

resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_cidrs.gateway]
}

resource "azurerm_subnet" "appgateway" {
  name                 = "${var.prefix}-appgateway-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_cidrs.appgateway]
}

resource "azurerm_subnet" "web" {
  name                 = "${var.prefix}-web-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_cidrs.web]
}

resource "azurerm_subnet" "data" {
  name                 = "${var.prefix}-data-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_cidrs.data]
  service_endpoints    = ["Microsoft.AzureCosmosDB"]
}

# Route Table for web subnet (to route traffic through firewall)
resource "azurerm_route_table" "web" {
  name                          = "${var.prefix}-web-rt"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  bgp_route_propagation_enabled = true
  tags                          = var.tags
}

# Associate route table to web subnet
resource "azurerm_subnet_route_table_association" "web" {
  subnet_id      = azurerm_subnet.web.id
  route_table_id = azurerm_route_table.web.id
}

# NSG — App Gateway subnet
# NSG — App Gateway subnet
resource "azurerm_network_security_group" "appgateway" {
  name                = "${var.prefix}-appgateway-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  # Required by Azure for App Gateway v2 (port range 65200-65535)
  security_rule {
    name                       = "Allow-GatewayManager"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-AzureLoadBalancer"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Internet-65200-65535"
    priority                   = 115
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTP-Inbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS-Inbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# NSG — Web subnet
resource "azurerm_network_security_group" "web" {
  name                = "${var.prefix}-web-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "Allow-HTTP-From-AppGateway"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = var.subnet_cidrs.appgateway
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH-From-VPN"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix = "172.16.0.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
  name                       = "Allow-HTTP-From-VPN"
  priority                   = 105
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "80"
  source_address_prefix      = "172.16.0.0/24"
  destination_address_prefix = "*"
}

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# NSG — Data subnet
resource "azurerm_network_security_group" "data" {
  name                = "${var.prefix}-data-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "Allow-CosmosDB-From-Web"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.subnet_cidrs.web
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-All-Inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# NSG associations
resource "azurerm_subnet_network_security_group_association" "appgateway" {
  subnet_id                 = azurerm_subnet.appgateway.id
  network_security_group_id = azurerm_network_security_group.appgateway.id
}

resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.web.id
  network_security_group_id = azurerm_network_security_group.web.id
}

resource "azurerm_subnet_network_security_group_association" "data" {
  subnet_id                 = azurerm_subnet.data.id
  network_security_group_id = azurerm_network_security_group.data.id
}

# Route table — force web subnet traffic through Azure Firewall
#resource "azurerm_route_table" "web" {
 # name                          = "${var.prefix}-web-rt"
  #location                      = var.location
  #resource_group_name           = var.resource_group_name
  #bgp_route_propagation_enabled = false
  #tags                          = var.tags

  #route {
   # name                   = "force-to-firewall"
    #address_prefix         = "0.0.0.0/0"
    #next_hop_type          = "VirtualAppliance"
    #next_hop_in_ip_address = var.firewall_private_ip
  #}
#}

#resource "azurerm_subnet_route_table_association" "web" {
 # subnet_id      = azurerm_subnet.web.id
  #route_table_id = azurerm_route_table.web.id
#}

