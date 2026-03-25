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

