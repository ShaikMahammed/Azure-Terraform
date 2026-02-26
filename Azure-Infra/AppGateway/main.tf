data "azurerm_virtual_network" "vnet" {
  name                = "Dev-vnet"
  resource_group_name = var.rg_name
}

resource "azurerm_public_ip" "pip" {
  name                = var.app_gw_public_ip_name
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
  location            = var.location
}

resource "azurerm_subnet" "appgwsubnet" {
  name                 = "appgw_subnet"
  resource_group_name  = var.rg_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
  address_prefixes     = var.appgw_subnet_prefix
}

resource "azurerm_application_gateway" "appgw" {
  name                = var.appgw_name
  location            = var.location
  resource_group_name = var.rg_name

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }
  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101" # This is a modern, secure policy
  }

  gateway_ip_configuration {
    name      = "appgw-ip"
    subnet_id = azurerm_subnet.appgwsubnet.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend"
    public_ip_address_id = azurerm_public_ip.pip.id
  }

 
  backend_address_pool {
    name = "appgw-backendpool"
  }

  backend_http_settings {
    name                  = "http-backend"
    port                  = 80
    protocol              = "Http"
    cookie_based_affinity = "Disabled"
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "appgw-frontend"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "routingrule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "appgw-backendpool"
    backend_http_settings_name = "http-backend"
    priority                   = 10 # V2 Gateways require a priority (1-20000)
  }
}

