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

resource "azurerm_network_security_group" "nsg1" {
  name = var.nsg_name
  resource_group_name = azurerm_resource_group.rg1.name
  location = azurerm_resource_group.rg1.location
}
#Adding an SSH rule 
resource "azurerm_network_security_rule" "nsg_rule" {
  name = "Allow-SSH"
  priority = 120
  direction = "Inbound"
  protocol = "Tcp"
  access = "Allow"
  resource_group_name = azurerm_resource_group.rg1.name
  network_security_group_name = azurerm_network_security_group.nsg1.name
  source_address_prefix = "*"
  source_port_range = "*"
  destination_address_prefix = "*"
  destination_port_range = "22"
}
#Attcahing the rule to subnet

resource "azurerm_subnet_network_security_group_association" "rule_association" {
  network_security_group_id = azurerm_network_security_group.nsg1.id
  subnet_id = azurerm_subnet.subnet.id
}