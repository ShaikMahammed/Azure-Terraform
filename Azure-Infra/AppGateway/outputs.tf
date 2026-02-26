output "app_gw_public_ip_name" {
  value = azurerm_application_gateway.appgw.name
}

output "app_Gw_subnet_name" {
  value = azurerm_subnet.appgwsubnet.name
  
}