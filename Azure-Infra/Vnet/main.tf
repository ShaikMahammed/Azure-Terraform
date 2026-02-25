resource "azurerm_resource_group" "rg1" {
  name = var.rg_name
  location = var.location
}
resource "azurerm_virtual_network" "vnet" {
  name = var.vnet_name
  location = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  address_space = var.address_space
}

resource "azurerm_subnet" "subnet" {
  name = var.subnet_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = var.subnet_prefix
  resource_group_name = azurerm_resource_group.rg1.name
}