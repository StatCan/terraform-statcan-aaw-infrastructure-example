resource "azurerm_key_vault" "vault" {
  name                        = "${var.prefix}-kv-vault"
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
    virtual_network_subnet_ids = concat(var.infrastructure_pipeline_subnet_ids, [data.azurerm_subnet.aks_system.id])
  }
}

# Allow the runner to managed key vault keys
resource "azurerm_key_vault_access_policy" "ci_vault_keys" {
  key_vault_id = azurerm_key_vault.vault.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  key_permissions = [
    "get",
    "create",
    "delete",
    "list"
  ]
}

resource "azurerm_key_vault_access_policy" "vault_vault_keys" {
  key_vault_id = azurerm_key_vault.vault.id

  tenant_id = azurerm_user_assigned_identity.vault.tenant_id
  object_id = azurerm_user_assigned_identity.vault.principal_id

  key_permissions = [
    "get",
    "wrapKey",
    "unwrapKey",
  ]
}

resource "azurerm_key_vault_key" "vault" {
  name         = "${var.prefix}-key-vault"
  key_vault_id = azurerm_key_vault.vault.id
  key_type     = "RSA-HSM"
  key_size     = 4096
  key_opts     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
}

resource "kubernetes_namespace" "vault_system" {
  metadata {
    name = "vault-system"

    labels = {
      "namespace.statcan.gc.ca/purpose"                = "daaas"
      "network.statcan.gc.ca/allow-ingress-controller" = "true"
      "istio-injection"                                = "enabled"
    }
  }
}

module "namespace_vault_system" {
  source = "git::https://github.com/canada-ca-terraform-modules/terraform-kubernetes-namespace.git?ref=v2.2.0"

  name = kubernetes_namespace.vault_system.id
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

# Managed Identity
resource "azurerm_user_assigned_identity" "vault" {
  resource_group_name = azurerm_resource_group.daaas_services.name
  location            = var.location
  tags                = var.tags

  name = "${var.prefix}-msi-vault"

  depends_on = []
}

# Allow msi to assign our identity
resource "azurerm_role_assignment" "aad_pod_identity_vault_operator" {
  scope                = azurerm_user_assigned_identity.vault.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = data.azurerm_kubernetes_cluster.cluster.kubelet_identity.0.object_id
}

module "vault_identity" {
  source = "git::https://github.com/StatCan/terraform-kubernetes-aad-pod-identity-template.git?ref=v2.x"

  identity_name = "vault"
  namespace     = kubernetes_namespace.vault_system.id

  type        = 0
  client_id   = azurerm_user_assigned_identity.vault.client_id
  resource_id = azurerm_user_assigned_identity.vault.id
}

# Create a storage account
module "vault_storage_account" {
  source = "git::https://github.com/StatCan/terraform-azurerm-storage-account.git?ref=v1.0.0"

  name                = "${var.prefix}-sa-vault"
  location            = var.location
  resource_group_name = azurerm_resource_group.daaas_services.name
  tags                = var.tags

  ip_rules                   = var.infrastructure_authorized_ip_ranges
  virtual_network_subnet_ids = concat([data.azurerm_subnet.aks_system.id], var.infrastructure_pipeline_subnet_ids)

  account_replication_type = "ZRS"
  containers = [
    "vault",
  ]
}

module "vault" {
  source = "git::https://github.com/StatCan/terraform-kubernetes-vault.git?ref=v3.x"

  depends_on = []

  helm_release_name = "vault"
  helm_namespace    = kubernetes_namespace.vault_system.id
  helm_repository   = "https://statcan.github.io/charts"

  values = <<EOF
vault:
  injector:
    enabled: false
  server:
    image:
      repository: k8scc01covidacr.azurecr.io/vault
      tag: 1.4.0
    authDelegator:
      enabled: false
    ingress:
      enabled: true
      hosts:
        - host: vault.aaw.example.ca
          paths:
          - '/.*'
      annotations:
        kubernetes.io/ingress.class: istio
    dataStorage:
      enabled: false
    extraLabels:
      aadpodidbinding: vault
    standalone:
      config: |
        ui = true
        plugin_directory = "/plugins"

        listener "tcp" {
          tls_disable = 1
          address = "[::]:8200"
          cluster_address = "[::]:8201"
        }

        seal "azurekeyvault" {
          tenant_id = "${data.azurerm_client_config.current.tenant_id}"
          vault_name = "${azurerm_key_vault.vault.name}"
          key_name = "${azurerm_key_vault_key.vault.name}"
        }

        storage "azure" {
          accountName = "${module.vault_storage_account.name}"
          accountKey = "${module.vault_storage_account.primary_access_key}"
          container = "vault"
        }

destinationRule:
  enabled: false
EOF
}
