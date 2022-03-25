resource "azurerm_storage_account" "storage" {
  name                      = substr(replace(var.name, "-", ""), 0, 24)
  location                  = var.location
  resource_group_name       = var.resource_group_name
  account_kind              = "StorageV2"
  account_tier              = "Standard"
  account_replication_type  = var.account_replication_type
  access_tier               = "Hot"
  enable_https_traffic_only = true
  allow_blob_public_access  = false
  min_tls_version           = "TLS1_2"

  tags = var.tags

  lifecycle {
    ignore_changes = [tags.DateCreatedModified]
  }
}

resource "azurerm_advanced_threat_protection" "storage" {
  target_resource_id = azurerm_storage_account.storage.id
  enabled            = true
}

resource "azurerm_storage_account_network_rules" "storage" {
  storage_account_name = azurerm_storage_account.storage.name
  resource_group_name  = var.resource_group_name

  default_action             = "Deny"
  virtual_network_subnet_ids = var.virtual_network_subnet_ids
  ip_rules                   = [for r in var.ip_rules : replace(r, "/32", "")]
  bypass                     = ["Logging", "Metrics", "AzureServices"]
}

resource "azurerm_storage_container" "storage" {
  for_each              = toset(var.containers)
  name                  = each.value
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}
