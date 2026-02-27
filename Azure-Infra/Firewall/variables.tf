variable "location" {}
variable "rg_name"{}
variable "vnet_name" {}
variable "Firewall_subnet_name" {}
variable "subnet_prefix" {
  type = list(string)
}
variable "vm_subnet_name" {}
variable "firewall_name" {}
variable "firewall_public_ip_name" {}
variable "route_table_name" {}