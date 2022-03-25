resource "azurerm_key_vault" "keys" {
  name                        = "${var.prefix}-kv-svcenc"
  location                    = var.location
  resource_group_name         = azurerm_resource_group.daaas_services.name
  tags                        = var.tags
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "premium"
  enabled_for_disk_encryption = true
  purge_protection_enabled    = true
  soft_delete_retention_days  = 90

  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    ip_rules                   = var.infrastructure_authorized_ip_ranges
    virtual_network_subnet_ids = var.infrastructure_pipeline_subnet_ids
  }
}

# Allow the runner to managed key vault keys
resource "azurerm_key_vault_access_policy" "ci_keys" {
  key_vault_id = azurerm_key_vault.keys.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  key_permissions = [
    "get",
    "create",
    "delete",
    "list"
  ]
}
