output "subnet_id" {
  value = azurerm_subnet.subnet.id
}

output "vm_public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}

#Deleted the VM in portal
