resource "azurerm_key_vault_key" "pgsql" {
  name         = "${var.name}-tfex-key"
  key_vault_id = var.key_vault_id
  key_type     = var.key_type
  key_size     = var.key_size
  key_opts     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
}

resource "azurerm_postgresql_server" "pgsql" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group

  administrator_login          = var.administrator_login
  administrator_login_password = length(data.azurerm_key_vault_secret.sqlhstsvc) > 0 ? data.azurerm_key_vault_secret.sqlhstsvc[0].value : var.administrator_login_password

  sku_name   = var.sku_name
  version    = var.pgsql_version
  storage_mb = var.storagesize_mb

  backup_retention_days        = 35
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  public_network_access_enabled    = var.public_network_access_enabled
  ssl_enforcement_enabled          = var.ssl_enforcement_enabled
  ssl_minimal_tls_version_enforced = var.ssl_minimal_tls_version_enforced

  tags = var.tags

  threat_detection_policy {
    disabled_alerts            = []
    email_account_admins       = true
    email_addresses            = var.emails
    enabled                    = true
    retention_days             = var.retention_days
    storage_endpoint           = var.keyvault_enable ? data.azurerm_storage_account.storageaccountinfo[0].primary_blob_endpoint : azurerm_storage_account.pgsql[0].primary_blob_endpoint
    storage_account_access_key = var.keyvault_enable ? data.azurerm_storage_account.storageaccountinfo[0].primary_access_key : azurerm_storage_account.pgsql[0].primary_access_key
  }

  identity {
    type = "SystemAssigned"
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }

}

resource "azurerm_postgresql_server_key" "pgsql" {
  server_id        = azurerm_postgresql_server.pgsql.id
  key_vault_key_id = azurerm_key_vault_key.pgsql.id
}

resource "azurerm_postgresql_database" "pgsql" {
  count               = length(var.database_names)
  name                = var.database_names[count.index].name
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  charset             = "UTF8"
  collation           = lookup(var.database_names[count.index], "collation", "English_United States.1252")
}

resource "azurerm_postgresql_active_directory_administrator" "pgsql" {
  server_name         = azurerm_postgresql_server.pgsql.name
  resource_group_name = var.resource_group
  login               = "sqladmin"
  tenant_id           = var.active_directory_administrator_object_id
  object_id           = var.active_directory_administrator_tenant_id
}

// Configure Server Logs
//
// https://docs.microsoft.com/en-us/azure/postgresql/howto-configure-server-logs-in-portal
//

resource "azurerm_postgresql_configuration" "client_min_messages" {
  name                = "client_min_messages"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.client_min_messages
}

resource "azurerm_postgresql_configuration" "debug_print_parse" {
  name                = "debug_print_parse"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.debug_print_parse
}

resource "azurerm_postgresql_configuration" "debug_print_plan" {
  name                = "debug_print_plan"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.debug_print_plan
}

resource "azurerm_postgresql_configuration" "debug_print_rewritten" {
  name                = "debug_print_rewritten"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.debug_print_rewritten
}

resource "azurerm_postgresql_configuration" "log_checkpoints" {
  name                = "log_checkpoints"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.log_checkpoints
}

resource "azurerm_postgresql_configuration" "log_connections" {
  name                = "log_connections"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.log_connections
}

resource "azurerm_postgresql_configuration" "log_disconnections" {
  name                = "log_disconnections"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.log_disconnections
}

resource "azurerm_postgresql_configuration" "log_duration" {
  name                = "log_duration"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.log_duration
}

resource "azurerm_postgresql_configuration" "log_error_verbosity" {
  name                = "log_error_verbosity"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.log_error_verbosity
}

resource "azurerm_postgresql_configuration" "log_line_prefix" {
  name                = "log_line_prefix"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.log_line_prefix
}

resource "azurerm_postgresql_configuration" "log_lock_waits" {
  name                = "log_lock_waits"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.log_lock_waits
}

resource "azurerm_postgresql_configuration" "log_min_duration_statement" {
  name                = "log_min_duration_statement"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.log_min_duration_statement
}

resource "azurerm_postgresql_configuration" "log_min_error_statement" {
  name                = "log_min_error_statement"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.log_min_error_statement
}

resource "azurerm_postgresql_configuration" "log_min_messages" {
  name                = "log_min_messages"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.log_min_messages
}

resource "azurerm_postgresql_configuration" "log_retention_days" {
  name                = "log_retention_days"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.log_retention_days
}

resource "azurerm_postgresql_configuration" "log_statement" {
  name                = "log_statement"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.log_statement
}

// Configure Security
//

resource "azurerm_postgresql_configuration" "row_security" {
  name                = "row_security"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.row_security
}

// Configure Performance
//

resource "azurerm_postgresql_configuration" "checkpoint_warning" {
  name                = "checkpoint_warning"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.checkpoint_warning
}

resource "azurerm_postgresql_configuration" "connection_throttling" {
  name                = "connection_throttling"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.connection_throttling
}

resource "azurerm_postgresql_configuration" "maintenance_work_mem" {
  name                = "maintenance_work_mem"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.maintenance_work_mem
}

resource "azurerm_postgresql_configuration" "min_wal_size" {
  name                = "min_wal_size"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.min_wal_size
}

resource "azurerm_postgresql_configuration" "max_wal_size" {
  name                = "max_wal_size"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.max_wal_size
}

resource "azurerm_postgresql_configuration" "pg_stat_statements_track_utility" {
  name                = "pg_stat_statements.track_utility"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.pg_stat_statements_track_utility
}

resource "azurerm_postgresql_configuration" "pg_qs_track_utility" {
  name                = "pg_qs.track_utility"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.pg_qs_track_utility
}

resource "azurerm_postgresql_configuration" "pg_qs_query_capture_mode" {
  name                = "pg_qs.query_capture_mode"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.pg_qs_query_capture_mode
}

resource "azurerm_postgresql_configuration" "pgms_wait_sampling_query_capture_mode" {
  name                = "pgms_wait_sampling.query_capture_mode"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.pgms_wait_sampling_query_capture_mode
}

resource "azurerm_postgresql_configuration" "synchronous_commit" {
  name                = "synchronous_commit"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.synchronous_commit
}

resource "azurerm_postgresql_configuration" "temp_buffers" {
  name                = "temp_buffers"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.temp_buffers
}

resource "azurerm_postgresql_configuration" "wal_buffers" {
  name                = "wal_buffers"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.wal_buffers
}

resource "azurerm_postgresql_configuration" "wal_writer_delay" {
  name                = "wal_writer_delay"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.wal_writer_delay
}

resource "azurerm_postgresql_configuration" "wal_writer_flush_after" {
  name                = "wal_writer_flush_after"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.wal_writer_flush_after
}

resource "azurerm_postgresql_configuration" "work_mem" {
  name                = "work_mem"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  value               = var.work_mem
}

// Configure Networking
//

resource "azurerm_postgresql_firewall_rule" "pgsql" {
  count               = length(var.firewall_rules)
  name                = azurerm_postgresql_server.pgsql.name
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  start_ip_address    = var.firewall_rules[count.index]
  end_ip_address      = var.firewall_rules[count.index]
}

resource "azurerm_postgresql_virtual_network_rule" "pgsql" {
  count = length(var.subnet_ids)

  name                = "${azurerm_postgresql_server.pgsql.name}-${count.index}"
  resource_group_name = var.resource_group
  server_name         = azurerm_postgresql_server.pgsql.name
  subnet_id           = var.subnet_ids[count.index]
}