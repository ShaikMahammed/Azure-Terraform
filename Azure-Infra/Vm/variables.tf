variable "location" {}
variable "rg_name"{}
variable "vnet_name" {}
variable "address_space" {
  type = list(string)
}
variable "subnet_name" {}
variable "subnet_prefix" {
  type = list(string)
}
variable "nsg_name" {}
variable "vm_name" {}
variable "vm_size" {}
variable "vm_publicip_name" {}
variable "nic_name" {}