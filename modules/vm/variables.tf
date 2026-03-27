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

variable "subnet_web_id" {
  description = "ID of the web subnet"
  type        = string
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B2als_v2"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  sensitive   = true
}

variable "zone" {
  description = "Availability zone for the VM"
  type        = string
  default     = "3"
}

variable "app_port" {
  description = "Port the web application listens on"
  type        = number
  default     = 3000
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}