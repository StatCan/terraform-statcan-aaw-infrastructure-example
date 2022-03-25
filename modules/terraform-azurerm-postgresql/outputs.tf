output "id" {
  value = azurerm_postgresql_server.pgsql.id
}

output "name" {
  value = azurerm_postgresql_server.pgsql.name
}

output "fqdn" {
  value = azurerm_postgresql_server.pgsql.fqdn
}

output "administrator_login" {
  value = "${azurerm_postgresql_server.pgsql.administrator_login}@${azurerm_postgresql_server.pgsql.name}"
}

output "identity_tenant_id" {
  value = azurerm_postgresql_server.pgsql.identity[0].tenant_id
}

output "identity_object_id" {
  value = azurerm_postgresql_server.pgsql.identity[0].principal_id
}
