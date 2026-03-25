# Azure
variable "subscription_id" {
  description = "Your Azure subscription ID"
  type        = string
  sensitive   = true
}

# Project
variable "prefix" {
  description = "Prefix for all resource names"
  type        = string
  default     = "pfa"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "francecentral"
}

variable "zone" {
  description = "Availability zone"
  type        = string
  default     = "3"
}

variable "tags" {
  description = "Tags for all resources"
  type        = map(string)
  default = {
    project     = "pfa"
    environment = "dev"
    managed_by  = "terraform"
  }
}

# VM
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

variable "app_port" {
  description = "Port the web application listens on"
  type        = number
  default     = 80
}