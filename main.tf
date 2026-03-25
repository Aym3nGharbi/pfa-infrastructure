terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.0"
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Resource Group
resource "azurerm_resource_group" "pfa" {
  name     = "${var.prefix}-rg"
  location = var.location
  tags     = var.tags
}

# ============================================
# MODULE: NETWORKING
# ============================================
module "networking" {
  source = "./modules/networking"

  location            = var.location
  resource_group_name = azurerm_resource_group.pfa.name
  prefix              = var.prefix
  tags                = var.tags

  # La variable firewall_private_ip est une valeur par défaut
  # Elle sera mise à jour après création du firewall
}

# ============================================
# MODULE: FIREWALL
# ============================================
module "firewall" {
  source = "./modules/firewall"

  location            = var.location
  resource_group_name = azurerm_resource_group.pfa.name
  prefix              = var.prefix
  tags                = var.tags

  firewall_subnet_id   = module.networking.subnet_firewall_id
  appgateway_private_ip = module.appgateway.appgateway_private_ip
  vm_subnet_cidr       = "10.0.3.0/24"
}

# ============================================
# ROUTE: Force web subnet traffic through firewall
# ============================================
resource "azurerm_route" "web_to_firewall" {
  name                   = "route-to-firewall"
  resource_group_name    = azurerm_resource_group.pfa.name
  route_table_name       = module.networking.web_route_table_name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.firewall.firewall_private_ip
}

# ============================================
# MODULE: VPN
# ============================================
module "vpn" {
  source = "./modules/vpn"

  location            = var.location
  resource_group_name = azurerm_resource_group.pfa.name
  prefix              = var.prefix
  tags                = var.tags

  subnet_gateway_id = module.networking.subnet_gateway_id
}

# ============================================
# MODULE: VM
# ============================================
module "vm" {
  source = "./modules/vm"

  location            = var.location
  resource_group_name = azurerm_resource_group.pfa.name
  prefix              = var.prefix
  tags                = var.tags

  subnet_web_id   = module.networking.subnet_web_id
  vm_size         = var.vm_size
  admin_username  = var.admin_username
  admin_password  = var.admin_password
  zone            = var.zone
  app_port        = var.app_port
}

# ============================================
# MODULE: APP GATEWAY (dépend du VM)
# ============================================
module "appgateway" {
  source = "./modules/appgateway"

  location            = var.location
  resource_group_name = azurerm_resource_group.pfa.name
  prefix              = var.prefix
  tags                = var.tags

  subnet_appgateway_id = module.networking.subnet_appgateway_id
  vm_private_ip        = module.vm.vm_private_ip
  app_port             = var.app_port
  zone                 = var.zone
}

# ============================================
# MODULE: COSMOS DB (dépend du networking)
# ============================================
module "cosmosdb" {
  source = "./modules/cosmosdb"

  location            = var.location
  resource_group_name = azurerm_resource_group.pfa.name
  prefix              = var.prefix
  tags                = var.tags

  subnet_data_id = module.networking.subnet_data_id
}

# ============================================
# MODULE: KEY VAULT (dépend de la VM pour l'identity)
# ============================================
module "keyvault" {
  source = "./modules/keyvault"

  location            = var.location
  resource_group_name = azurerm_resource_group.pfa.name
  prefix              = var.prefix
  tags                = var.tags

  tenant_id        = data.azurerm_client_config.current.tenant_id
  vm_principal_id  = module.vm.vm_identity_principal_id
}

# ============================================
# DATA SOURCE: Client config pour tenant_id
# ============================================
data "azurerm_client_config" "current" {}

# ============================================
# UPDATE ROUTE TABLE avec l'IP réelle du firewall
# ============================================
# On doit mettre à jour la route table après création du firewall
# car l'IP privée n'est connue qu'après

# resource "azurerm_route_table" "web_update" {
#   name                          = "${var.prefix}-web-rt"
#   location                      = var.location
#   resource_group_name           = azurerm_resource_group.pfa.name
#   bgp_route_propagation_enabled = false
#   tags                          = var.tags

#   route {
#     name                   = "force-to-firewall"
#     address_prefix         = "0.0.0.0/0"
#     next_hop_type          = "VirtualAppliance"
#     next_hop_in_ip_address = module.firewall.firewall_private_ip
#   }

#   depends_on = [module.firewall]
# }

# resource "azurerm_subnet_route_table_association" "web" {
#   subnet_id      = module.networking.subnet_web_id
#   route_table_id = azurerm_route_table.web_update.id

#   depends_on = [azurerm_route_table.web_update]
# }