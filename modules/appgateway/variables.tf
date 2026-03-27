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

variable "subnet_appgateway_id" {
  description = "ID of the App Gateway subnet"
  type        = string
}

variable "vm_private_ip" {
  description = "Private IP of the backend VM"
  type        = string
}

variable "app_port" {
  description = "Port the web application listens on"
  type        = number
  default     = 3000
}

variable "zone" {
  description = "Availability zone"
  type        = string
  default     = "3"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "appgateway_pfx_password" {
  description = "Password for the PFX certificate used by Application Gateway HTTPS"
  type        = string
  default     = ""
  sensitive   = true
}

variable "appgateway_pfx_path" {
  description = "Path to a PFX certificate file for Application Gateway HTTPS (if empty, HTTPS listener is disabled)"
  type        = string
  default     = ""
}

