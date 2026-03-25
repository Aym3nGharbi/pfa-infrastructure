variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "prefix" {
  description = "Resource prefix"
  type        = string
}

variable "tags" {
  description = "Tags"
  type        = map(string)
}

variable "firewall_subnet_id" {
  description = "ID of the AzureFirewallSubnet"
  type        = string
}

variable "appgateway_private_ip" {
  description = "Private IP of App Gateway for DNAT"
  type        = string
}

variable "vm_subnet_cidr" {
  description = "CIDR of VM subnet for source addresses"
  type        = string
}