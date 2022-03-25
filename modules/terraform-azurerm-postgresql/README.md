# Terraform for Azure Managed Database PostgreSQL

Creates a PostgreSQL instance using the Azure Managed Database for PostgreSQL service.

## Security Controls

* Adheres to the [CIS Microsoft Azure Foundations Benchmark 1.3.0](https://docs.microsoft.com/en-us/azure/governance/policy/samples/cis-azure-1-3-0) for Database Services.

## Dependencies

* Terraform v0.14.x +
* Terraform AzureRM Provider 2.5 +

## Enabling Extensions

Azure Database for PostgreSQL supports a subset of key extensions that are listed in the link below. This information is also available by running `SELECT * FROM pg_available_extensions;`.

For instance, application teams that have functionality that needs encryption can enable pg_crypto by using the `CREATE EXTENSION` command.

https://docs.microsoft.com/en-us/azure/postgresql/concepts-extensions

## Notes on Collation

The Azure Managed Database for Postgresql is currently using the Windows O.S. As such the collation names are different.

```sh
sudo -u postgres pg_dump -Fp —no-owner DBNAME | sed "/COLLATE/s/en_US.utf8/English_United States.1252/ig" | sed "/CREATE COLLATION/s/en_US.utf8/English_United States.1252/ig" | psql --host=aaa.postgres.database.azure.com --port=5432 --username=xxx@yyy --dbname=DBNAME
```

Reference: https://stackoverflow.com/questions/47791728/azure-postgresql-server-service-collation-create-error

## Usage

Examples for this module along with various configurations can be found in the [examples/](examples/) folder.

## Variables

| Name                                     | Type   | Default           | Required | Description                                                                                                                          |
|------------------------------------------|--------|-------------------|----------|--------------------------------------------------------------------------------------------------------------------------------------|
| active_directory_administrator_object_id | string | `""`              | no       | The Active Directory Administrator Object ID.                                                                                        |
| active_directory_administrator_tenant_id | string | `""`              | no       | The Active Directory Administrator Tenant ID.                                                                                        |
| administrator_login                      | string | n/a               | yes      | The Administrator Login for the PostgreSQL Server.                                                                                   |
| administrator_login_password             | string | n/a               | yes      | The Password associated with the administrator_login for the PostgreSQL Server.                                                      |
| database_names                           | list   | n/a               | yes      | The name of the PostgreSQL database(s).                                                                                              |
| dependencies                             | list   | n/a               | yes      | Dependency management of resources.                                                                                                  |
| emails                                   | list   | n/a               | yes      | List of email addresses that should recieve the security reports.                                                                    |
| firewall_rules                           | list   | n/a               | yes      | Specifies the Start IP Address associated with this Firewall Rule.                                                                   |
| key_vault_id                             | string | `""`              | no       | The Key Vault id for the Customer Managed Key.                                                                                       |
| kv_name                                  | string | `""`              | no       | The Key Vault name.                                                                                                                  |
| kv_rg                                    | string | `""`              | no       | The Key Vault resource group.                                                                                                        |
| location                                 | string | `"canadacentral"` | no       | Specifies the supported Azure location where the resource exists.                                                                    |
| name                                     | string | n/a               | yes      | The name of the PostgreSQL Server.                                                                                                   |
| pgsql_version                            | string | `"9.6"`           | no       | The version of the PostgreSQL Server.                                                                                                |
| public_network_access_enabled            | string | `"false"`         | no       | Whether or not public network access is allowed for this server.                                                                     |
| resource_group                           | string | n/a               | yes      | The name of the resource group in which to create the PostgreSQL Server.                                                             |
| sku_name                                 | string | `"GP_Gen5_4"`     | no       | Specifies the SKU Name for this PostgreSQL Server.                                                                                   |
| ssl_enforcement_enabled                  | string | `"true"`          | no       | Specifies if SSL should be enforced on connections.                                                                                  |
| ssl_minimal_tls_version_enforced         | string | `"TLS1_2"`        | no       | The mimimun TLS version to support on the sever.                                                                                     |
| storagesize_mb                           | string | `"640000"`        | no       | Specifies the version of PostgreSQL to use.                                                                                          |
| subnet_id                                | string | n/a               | yes      | The ID of the subnet that the PostgreSQL server will be connected to.                                                                |
| storageaccountinfo_resource_group_name   | string | n/a               | yes      | The storageaccountinfo resource group name.                                                                                          |
| tags                                     | map    | `"<map>"`         | n/a      | A mapping of tags to assign to the resource.                                                                                         |
| keyvault_enable                            | string | `"false"`         | no       | Enable Threat Detection Policy.                                                                                                      |
| client_min_messages                      | string | `"log"`           | no       | Sets the message levels that are sent to the client.                                                                                 |
| debug_print_parse                        | string | `"off"`           | no       | Logs each query's parse tree.                                                                                                        |
| debug_print_plan                         | string | `"off"`           | no       | Logs each query's execution plan.                                                                                                    |
| debug_print_rewritten                    | string | `"off"`           | no       | Logs each query's rewritten parse tree.                                                                                              |
| log_checkpoints                          | string | `"off"`           | no       | Logs each checkpoint.                                                                                                                |
| log_connections                          | string | `"on"`            | no       | Logs each successful connection.                                                                                                     |
| log_disconnections                       | string | `"on"`            | no       | Logs end of a session, including duration.                                                                                           |
| log_duration                             | string | `"off"`           | no       | Logs the duration of each completed SQL statement.                                                                                   |
| log_error_verbosity                      | string | `"default"`       | no       | Sets the verbosity of logged messages.                                                                                               |
| log_line_prefix                          | string | `"%t-%c-"`        | no       | Sets the printf-style string that is output at the beginning of each log line.                                                       |
| log_lock_waits                           | string | `"off"`           | no       | Logs long lock waits.                                                                                                                |
| log_min_duration_statement               | string | `"10"`            | no       | Sets the minimum execution time (in milliseconds) above which statements will be logged.                                             |
| log_min_error_statement                  | string | `"error"`         | no       | Causes all statements generating error at or above this level to be logged.                                                          |
| log_min_messages                         | string | `"warning"`       | no       | Sets the message levels that are logged.                                                                                             |
| log_retention_days                       | string | `"7"`             | no       | Sets how many days a log file is saved for.                                                                                          |
| log_statement                            | string | `"ddl"`           | no       | Sets the type of statements logged.                                                                                                  |
| row_security                             | string | `"on"`            | no       | Enable row security.                                                                                                                 |
| checkpoint_warning                       | string | `"0"`             | no       | Enables warnings if checkpoint segments are filled more frequently than this.                                                        |
| connection_throttling                    | string | `"on"`            | no       | Enables temporary connection throttling per IP for too many invalid password login failures.                                         |
| maintenance_work_mem                     | string | `"32000"`         | no       | Sets the maximum memory to be used for maintenance operations. Unit is kb.                                                           |
| min_wal_size                             | string | `"512"`           | no       | Sets the minimum size to shrink the WAL to. Unit is mb.                                                                              |
| max_wal_size                             | string | `"512"`           | no       | Sets the WAL size that triggers a checkpoint. Unit is mb.                                                                            |
| pg_stat_statements_track_utility         | string | `"off"`           | no       | Selects whether utility commands are tracked by pg_stat_statements.                                                                  |
| pg_qs_track_utility                      | string | `"on"`            | no       | Selects whether utility commands are tracked by pg_qs.                                                                               |
| pg_qs_query_capture_mode                 | string | `"top"`           | no       | Selects which statements are tracked by pg_qs.                                                                                       |
| pgms_wait_sampling_query_capture_mode    | string | `"all"`           | no       | Selects which statements are tracked by the pgms_wait_sampling extension.                                                            |
| synchronous_commit                       | string | `"on"`            | no       | Sets the current transaction's synchronization level.                                                                                |
| temp_buffers                             | string | `"16384"`         | no       | Sets the maximum number of temporary buffers used by each database session. Unit is 8kb.                                             |
| wal_buffers                              | string | `"8192"`          | no       | Sets the number of disk-page buffers in shared memory for WAL. Unit is 8kb.                                                          |
| wal_writer_delay                         | string | `"200"`           | no       | Time between WAL flushes performed in the WAL writer. Unit is ms.                                                                    |
| wal_writer_flush_after                   | string | `"128"`           | no       | Amount of WAL written out by WAL writer that triggers a flush. Unit is 8kb.                                                          |
| work_mem                                 | string | `"2048000"`       | no       | Sets the amount of memory to be used by internal sort operations and hash tables before writing to temporary disk files. Unit is kb. |

## History

| Date     | Release    | Change                                                 |
|----------|------------|--------------------------------------------------------|
| 20210510 | 20210510.1 | The v1.0.1 release which adds optional support for ATP |
| 20210207 | 20210207.1 | The v1.0.0 release of Terraform module                 |
