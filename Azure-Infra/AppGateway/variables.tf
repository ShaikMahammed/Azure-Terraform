variable "rg_name" {}
variable "location" {}
variable "vnet_name" {}
variable "appgw_subnet_name" {}
variable "appgw_subnet_prefix" {
  type = list(string)
}
variable "app_gw_public_ip_name"{}
variable "appgw_name"{}
variable "backend_ip" {}