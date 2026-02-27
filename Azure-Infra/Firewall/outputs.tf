output "firewall_name" {
  value = azurerm_firewall.firewall.name
}

output "dnat_name" {
  value = azurerm_firewall_nat_rule_collection.dnat_ssh.name
}