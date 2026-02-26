output "subnet_id" {
  value = azurerm_subnet.subnet.id
}
output "nsg_id" {
  value = azurerm_network_security_group.nsg.id
  
}
output "vm_public_ip" {
  value = azurerm_public_ip.public_ip1.ip_address
}

#Deleted the VM in portal
