terraform {
  backend "azurerm" {
    resource_group_name = "storage-RG" 
    storage_account_name = "mlok"
    container_name = "tfstate"
    key = "terraform.tfstate"
  
  }
}