data "azurerm_kubernetes_cluster" "cluster" {
  name                = "${var.prefix}-aks"
  resource_group_name = "${var.prefix}-rg-aks"
}
