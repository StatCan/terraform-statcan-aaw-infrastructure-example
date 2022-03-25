resource "azurerm_resource_group" "daaas_services" {
  name     = "${var.prefix}-rg-daaas-services"
  location = var.location
  tags     = var.tags

  lifecycle {
    ignore_changes = [tags.DateCreatedModified]
  }
}

# The principal running the terraform needs to be
# an "Owner" on the resource group in order
# to deploy resources and assign permission.
resource "azurerm_role_assignment" "daaas_services_rg_owner_ci" {
  scope                = azurerm_resource_group.daaas_services.id
  role_definition_name = "Owner"
  principal_id         = data.azurerm_client_config.current.object_id
}
