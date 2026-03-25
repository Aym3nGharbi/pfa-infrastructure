variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "subnet_gateway_id" {
  description = "ID of the GatewaySubnet"
  type        = string
}

variable "vpn_client_address_pool" {
  description = "Address pool for VPN clients — your laptop will get an IP from here"
  type        = string
  default     = "172.16.0.0/24"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}