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

resource "azurerm_public_ip" "public_ip" {
  name = "Public-Ip"
  resource_group_name = azurerm_resource_group.rg1.name
  location = azurerm_resource_group.rg1.location
  allocation_method = "Static"
  sku = "Standard"
}

resource "azurerm_network_interface" "nic" {
  name = "nic-01"
  location = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  ip_configuration {
    name = "internal"
    private_ip_address_allocation = "Dynamic"
    subnet_id = azurerm_subnet.subnet.id
    public_ip_address_id = azurerm_public_ip.public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "Vm01" {
  name = var.vm_name
  resource_group_name = azurerm_resource_group.rg1.name
  location = azurerm_resource_group.rg1.location
  size = var.vm_size
  admin_username = "vm01"
  admin_password = "Asdf@1234567890"
  disable_password_authentication = false
  network_interface_ids = [ azurerm_network_interface.nic.id ]

  os_disk {
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  
  source_image_reference{
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}