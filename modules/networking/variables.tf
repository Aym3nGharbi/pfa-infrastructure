variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "prefix" {
  description = "Prefix used for all resource names"
  type        = string
}

variable "vnet_cidr" {
  description = "CIDR block for the Virtual Network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  description = "CIDR blocks for each subnet"
  type = object({
    firewall = string
    # firewall_mgmt = string ← Supprimer
    gateway    = string
    appgateway = string
    web        = string
    data       = string
  })
  default = {
    firewall = "10.0.0.0/26"
    # firewall_mgmt = "10.0.0.64/26"  ← Supprimer
    gateway    = "10.0.1.0/27"
    appgateway = "10.0.2.0/24"
    web        = "10.0.3.0/24"
    data       = "10.0.4.0/24"
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

#variable "firewall_private_ip" {
# description = "Private IP of Azure Firewall — used for UDR route table"
# type        = string
# default     = "10.0.0.4"
#}