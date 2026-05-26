variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "prefix" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "vm_principal_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "appgateway_pfx_path" {
  description = "Optional path to a PFX file to import into Key Vault for App Gateway"
  type        = string
  default     = ""
}

variable "appgateway_pfx_password" {
  description = "Password for the PFX file to import into Key Vault"
  type        = string
  default     = ""
  sensitive   = true
}

