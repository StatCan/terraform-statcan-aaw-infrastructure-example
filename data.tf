data "azurerm_client_config" "current" {}

data "azurerm_subnet" "aks_system" {
  name                 = "aaw-prod-cc-00-snet-aks-system"
  virtual_network_name = "aaw-prod-cc-00-vnet-aks"
  resource_group_name  = "aaw-prod-cc-00-rg-network"
}
