###########################################################
# jFrog
###########################################################
# Artifactory/X-Ray instance to store artifacts
# for use by the Advanced Analytics Workspaces (AAW).
###########################################################

# Generate a unique PGSQL username
resource "random_pet" "jfrog_postgresql_username" {
  length    = 2
  separator = ""
}

# Generate a unique PGSQL password
resource "random_password" "jfrog_postgresql" {
  length      = 24
  special     = true
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
}

resource "random_password" "jfrog_artifactory_postgresql" {
  length      = 24
  special     = true
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
  min_special = 1
}

resource "random_password" "jfrog_xray_postgresql" {
  length      = 24
  special     = false # xray doesn't like special characters
  min_lower   = 1
  min_upper   = 1
  min_numeric = 1
}

# Storage account
# ---------------
module "jfrog_storage_account" {
  source = "./modules/terraform-azurerm-storage-account"

  # Metadata
  name                = "${var.prefix}-sa-jfrog"
  location            = var.location
  resource_group_name = azurerm_resource_group.daaas_services.name
  tags                = var.tags

  # Network rules
  # (e.g., allow infrastructure IPs to configure
  #  the storage account, allow cluster system subnet)
  ip_rules                   = var.infrastructure_authorized_ip_ranges
  virtual_network_subnet_ids = concat([data.azurerm_subnet.aks_system.id], var.infrastructure_pipeline_subnet_ids)

  account_replication_type = "ZRS" # Use zone-redundant storage
  containers               = ["artifactory"]
}

# Create an encryption key to encrypt storage
resource "azurerm_key_vault_key" "jfrog_storage" {
  depends_on = [
    azurerm_key_vault_access_policy.ci_keys
  ]

  name         = "${var.prefix}-key-jfrog-storage"
  key_vault_id = azurerm_key_vault.keys.id

  # Use an HSM-backed key
  key_type = "RSA-HSM"

  # Key size of 3072 is recommended by 2030, 4096 is largest supported
  # https://cyber.gc.ca/en/guidance/cryptographic-algorithms-unclassified-protected-and-protected-b-information-itsp40111
  key_size = "4096"

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}

resource "azurerm_storage_account_customer_managed_key" "jfrog" {
  storage_account_id = module.jfrog_storage_account.id
  key_vault_id       = azurerm_key_vault.keys.id
  key_name           = azurerm_key_vault_key.jfrog_storage.name
}

# PostgreSQL
module "jfrog_postgresql" {
  source = "./modules/terraform-azurerm-postgresql"

  name = "${var.prefix}-pgsql-jfrog"
  database_names = [
    { name = "platform" }
  ]

  administrator_login          = random_pet.jfrog_postgresql_username.id
  administrator_login_password = random_password.jfrog_postgresql.result

  sku_name       = "GP_Gen5_4"
  pgsql_version  = "11"
  storagesize_mb = 512000

  key_type = "RSA-HSM"
  key_size = 2048

  location       = var.location
  resource_group = azurerm_resource_group.daaas_services.name
  subnet_ids     = concat([data.azurerm_subnet.aks_system.id], var.infrastructure_pipeline_subnet_ids)
  firewall_rules = [for r in var.infrastructure_authorized_ip_ranges : replace(r, "/32", "")]

  # DAaaS-AAW-Platform-Admins
  active_directory_administrator_object_id = "XXX"
  active_directory_administrator_tenant_id = data.azurerm_client_config.current.tenant_id

  public_network_access_enabled    = true
  ssl_enforcement_enabled          = true
  ssl_minimal_tls_version_enforced = "TLS1_2"

  keyvault_enable = false

  # Params
  client_min_messages = "warning"

  emails = [
    "william.hearn@canada.ca",
    "zachary.seguin@canada.ca"
  ]

  tags = {
    "serviceLine"        = "postgresqlazdb"
    "tier"               = "k8s"
    "buildVersion"       = "v0"
    "buildCertification" = "None"
    "supportTeam"        = "daaas"
    "terraformModule"    = "postgressqldb?ref=v1.0.1"
  }

  key_vault_id = azurerm_key_vault.keys.id

  depends_on = [
    azurerm_key_vault_access_policy.ci_keys
  ]
}

# Allow the runner to managed key vault keys
resource "azurerm_key_vault_access_policy" "jfrog_postgresql" {
  key_vault_id = azurerm_key_vault.keys.id

  tenant_id = module.jfrog_postgresql.identity_tenant_id
  object_id = module.jfrog_postgresql.identity_object_id

  key_permissions = [
    "get",
    "wrapKey",
    "unwrapKey"
  ]
}

##
## Deploy Artifactory
##
resource "kubernetes_namespace" "jfrog_system" {
  metadata {
    name = "jfrog-system"

    labels = {
      "namespace.statcan.gc.ca/purpose" = "daaas"
    }
  }
}

module "namespace_jfrog_system" {
  source = "git::https://github.com/canada-ca-terraform-modules/terraform-kubernetes-namespace.git?ref=v2.2.0"

  name = kubernetes_namespace.jfrog_system.id
  namespace_admins = {
    users  = []
    groups = ["XXXX"]
  }

  # CI/CD
  ci_name = "ci"

  # Image Pull Secret
  enable_kubernetes_secret = 0

  # Dependencies
  dependencies = []
}

resource "kubernetes_secret" "jfrog_database" {
  metadata {
    name      = "jfrog-postgresql"
    namespace = kubernetes_namespace.jfrog_system.id
  }

  type = "Opaque"

  data = {
    "admin-user"     = module.jfrog_postgresql.administrator_login
    "admin-password" = random_password.jfrog_postgresql.result
  }
}

resource "helm_release" "jfrog" {
  name       = "jfrog-platform"
  repository = "https://charts.jfrog.io"
  chart      = "jfrog-platform"
  version    = "0.4.1"
  timeout    = 3600

  namespace = kubernetes_namespace.jfrog_system.id

  values = [<<EOF
global:
  joinKey: ${var.jfrog_join_key}
  masterKey: ${var.jfrog_master_key}
  versions:
    artifactory: 7.19.13
    xray: 3.26.1

  database:
    initDBCreation: false
    host: ${module.jfrog_postgresql.fqdn}
    sslMode: require
    secrets:
      adminUsername:
        name: ${kubernetes_secret.jfrog_database.metadata.0.name}
        key: "admin-user"
      adminPassword:
        name: ${kubernetes_secret.jfrog_database.metadata.0.name}
        key: "admin-password"

# We are using an external database
postgresql:
  enabled: false

artifactory-ha:
  database:
    user: artifactoryha@${module.jfrog_postgresql.name}
    password: '${random_password.jfrog_artifactory_postgresql.result}'

  artifactory:
    startupProbe:
      enabled: false

    node:
      replicaCount: 0

    persistence:
      maxCacheSize: '50000000000'
      type: azure-blob
      azureBlob:
        accountName: ${module.jfrog_storage_account.name}
        accountKey: ${module.jfrog_storage_account.primary_access_key}
        endpoint: '${module.jfrog_storage_account.primary_blob_endpoint}'
        containerName: artifactory
        multiPartLimit: '100000000'
        multipartElementSize: '50000000'

  nginx:
    enabled: false

  ingress:
    enabled: false

xray:
  enabled: true
  database:
    user: xray@${module.jfrog_postgresql.name}
    actualUsername: xray
    password: '${random_password.jfrog_xray_postgresql.result}'

mission-control:
  enabled: false

distribution:
  enabled: false

pipelines:
  enabled: false
EOF
  ]
}

resource "kubernetes_ingress" "jfrog" {
  metadata {
    name      = "jfrog-platform"
    namespace = kubernetes_namespace.jfrog_system.id
    annotations = {
      "kubernetes.io/ingress.class" = "istio"
    }
  }

  spec {
    rule {
      host = "jfrog.aaw.example.ca"
      http {
        path {
          backend {
            service_name = "jfrog-platform-artifactory-ha"
            service_port = 8082
          }

          path = "/*"
        }

        path {
          backend {
            service_name = "jfrog-platform-artifactory-ha"
            service_port = 8081
          }

          path = "/artifactory/*"
        }
      }
    }
  }
}
