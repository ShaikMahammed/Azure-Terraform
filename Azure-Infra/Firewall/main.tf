# ----------------------------------------------------------------------------------
# DATA SOURCES: Reference existing infrastructure.
# We pull the VNet and Subnet IDs to ensure the Firewall is injected into the correct network.
# ----------------------------------------------------------------------------------
data "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.rg_name
}

data "azurerm_resource_group" "rg1" {
  name = var.rg_name
}

data "azurerm_subnet" "vm_subnet" {
  name                 = var.vm_subnet_name
  resource_group_name  = var.rg_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
}

# ----------------------------------------------------------------------------------
# FIREWALL SUBNET: Azure requires a dedicated subnet named EXACTLY "AzureFirewallSubnet".
# This subnet must be large enough (min /26) to handle firewall scaling.
# ----------------------------------------------------------------------------------
resource "azurerm_subnet" "firewallsubnet" {
  name                 = var.Firewall_subnet_name # Ensure this is "AzureFirewallSubnet"
  address_prefixes     = var.subnet_prefix
  resource_group_name  = data.azurerm_resource_group.rg1.name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
}

resource "azurerm_public_ip" "firewallpublicip" {
  name                = var.firewall_public_ip_name
  allocation_method   = "Static"
  sku                 = "Standard" # Standard SKU is mandatory for Azure Firewall
  resource_group_name = data.azurerm_resource_group.rg1.name
  location            = var.location
}

# ----------------------------------------------------------------------------------
# FIREWALL INSTANCE: The "Brain" of your network security.
# It uses an IP configuration to link the Public IP and the dedicated subnet.
# ----------------------------------------------------------------------------------
resource "azurerm_firewall" "firewall" {
  name                = var.firewall_name
  resource_group_name = data.azurerm_resource_group.rg1.name
  location            = var.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"

  ip_configuration {
    name                 = "Firewall-Ipconfig"
    subnet_id            = azurerm_subnet.firewallsubnet.id
    public_ip_address_id = azurerm_public_ip.firewallpublicip.id
  }
}

# ----------------------------------------------------------------------------------
# ROUTE TABLE (UDR): This forces traffic to "hop" through the Firewall.
# Without this, the VM would bypass the Firewall and go straight to the internet.
# ----------------------------------------------------------------------------------
resource "azurerm_route_table" "firewall_udr" {
  name                = var.route_table_name
  resource_group_name = data.azurerm_resource_group.rg1.name
  location            = var.location
}

# 0.0.0.0/0 means "All Internet Traffic"
# VirtualAppliance tells Azure to send that traffic to the Firewall's Private IP.
resource "azurerm_route" "default_route" {
  name                   = "Internet-via-Firewall"
  resource_group_name    = data.azurerm_resource_group.rg1.name
  route_table_name       = azurerm_route_table.firewall_udr.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
}

# This "hooks" the route table to your VM's subnet.
resource "azurerm_subnet_route_table_association" "websubnet-udr-assoc" {
  subnet_id      = data.azurerm_subnet.vm_subnet.id
  route_table_id = azurerm_route_table.firewall_udr.id
}

# ----------------------------------------------------------------------------------
# NETWORK RULE: Filtering traffic by IP/Port (Layer 4).
# This allows your VM to reach the internet for updates/browsing on 80/443.
# ----------------------------------------------------------------------------------
resource "azurerm_firewall_network_rule_collection" "allow_internet" {
  name                = "Allow-Internet_Network_rule"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = data.azurerm_resource_group.rg1.name
  priority            = 140
  action              = "Allow"

  rule {
    name                  = "allow-http-https"
    source_addresses      = ["10.0.1.0/24"] # The internal range of your VM --> Vm lies in this subnet
    destination_addresses = ["*"]
    destination_ports     = ["80", "443"]
    protocols             = ["TCP"]
  }
}

# ----------------------------------------------------------------------------------
# NAT RULE (DNAT): "Inbound" access.
# This maps the Firewall's Public IP (Port 22) to the Private IP of your VM.
# Use this to SSH into your VM without giving the VM its own Public IP.
# ----------------------------------------------------------------------------------
resource "azurerm_firewall_nat_rule_collection" "dnat_ssh" {
  name                = "Allow-ssh"
  resource_group_name = data.azurerm_resource_group.rg1.name
  azure_firewall_name = azurerm_firewall.firewall.name
  priority            = 120
  action              = "Dnat"

  rule {
    name                  = "ssh_vm"
    source_addresses      = ["*"] 
    destination_addresses = [azurerm_public_ip.firewallpublicip.ip_address]  #ssh
    destination_ports     = ["22"]
    translated_address    = "10.0.1.5" # The Private IP of your existing VM
    translated_port       = "22"
    protocols             = ["TCP"]
  }
}