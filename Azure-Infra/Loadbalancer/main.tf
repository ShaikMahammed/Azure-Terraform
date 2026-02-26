data "azurerm_network_interface" "vm_nic"{
  name = "nic-02"      #same name as in the portal 
  resource_group_name = var.rg_name
}

resource "azurerm_public_ip" "lb_public_ip" {
  name = var.lb_public_ip_name
  allocation_method = "Static"
  resource_group_name = var.rg_name
  location = var.location
  sku = "Standard"
}

resource "azurerm_lb" "lb" {
  name = var.lb_name
  resource_group_name = var.rg_name
  location = var.location
  sku = "Standard"
  frontend_ip_configuration {
    name = "Lb_FrontendIp"
    public_ip_address_id = azurerm_public_ip.lb_public_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  name = "LB-backendpool"
  loadbalancer_id = azurerm_lb.lb.id
}

#Attaching VM's NIC to Load balancer backend Pool
resource "azurerm_network_interface_backend_address_pool_association" "vm_attach" {
  network_interface_id = data.azurerm_network_interface.vm_nic.id
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
  ip_configuration_name = "internal"
}

resource "azurerm_lb_probe" "health_probe" {
  name = "lb_health_probe"
  loadbalancer_id = azurerm_lb.lb.id
  port = 80
}

resource "azurerm_lb_rule" "rule" {
  name = "Lb_rule"
  loadbalancer_id = azurerm_lb.lb.id
  frontend_port = 80
  backend_port = 80
  protocol = "Tcp"
  frontend_ip_configuration_name = "Lb_FrontendIp"  #Same as the above frontend ip name 
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.backend_pool.id] 
  probe_id = azurerm_lb_probe.health_probe.id
}
