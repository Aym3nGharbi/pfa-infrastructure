variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "prefix" {
  type = string
}

variable "subnet_data_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}