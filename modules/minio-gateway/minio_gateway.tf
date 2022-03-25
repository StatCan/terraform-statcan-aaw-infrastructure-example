##
## Minio Gateway Instances
##
resource "kubernetes_namespace" "minio_gateway_system" {
  metadata {
    name = var.namespace

    labels = {
      "istio-injection"                 = "enabled"
      "namespace.statcan.gc.ca/purpose" = "daaas"
      "namespace.statcan.gc.ca/use"     = "minio"
      # TODO: Change this once things are ready
      "network.statcan.gc.ca/allow-ingress-controller" = tostring(var.ingress_enabled || var.boathouse_enabled)
    }
  }
}

module "namespace_minio_gateway_system" {
  source = "git::https://github.com/canada-ca-terraform-modules/terraform-kubernetes-namespace.git?ref=v2.2.0"

  name = kubernetes_namespace.minio_gateway_system.id
  namespace_admins = {
    users = []
    groups = var.admins
  }

  # CI/CD
  ci_name = "ci"

  # Image Pull Secret
  enable_kubernetes_secret = 0

  # Dependencies
  dependencies = []
}

resource "random_password" "minio_gateway_access_key" {
  length  = 24
  special = false
}

resource "random_password" "minio_gateway_secret_key" {
  length  = 36
  special = false
}

resource "kubernetes_secret" "minio_secret" {
  metadata {
    name      = "minio-gateway-secret"
    namespace = var.namespace
  }

  data = {
    access-key = random_password.minio_gateway_access_key.result
    secret-key = random_password.minio_gateway_secret_key.result
  }
}

resource "kubernetes_secret" "gateway_azure_blob_secret" {
  metadata {
    name      = "azure-blob-storage"
    namespace = var.namespace
  }

  data = {
    storageAccountName = var.storageAccountName
    storageAccountKey  = var.storageAccountKey
    rg                 = var.storage_account_rg
    subscription       = var.storage_account_subscription
  }
}

resource "kubernetes_secret" "openid_secret" {
  # secert created only if openid_instance variable is set to true
  count = var.openid_instance ? 1 : 0

  metadata {
    name      = "minio-gateway-openid-secret"
    namespace = var.namespace
  }

  data = {
    MINIO_IDENTITY_OPENID_CONFIG_URL = var.minio_identity_openid_config_url
    MINIO_IDENTITY_OPENID_CLIENT_ID = var.minio_identity_openid_client_id
  }
}

resource "kubernetes_ingress" "minio" {
  count = var.boathouse_enabled ? 1 : 0

  metadata {
    name = "minio-gateway"
    namespace = var.namespace
    annotations = {
      "kubernetes.io/ingress.class" = "istio"
    }
  }
 
  spec {
    rule {
      host = "${var.namespace}-boathouse.${var.domain}"
      http {
        path {
          backend {
            service_name = "minio-gateway"
            service_port = 9000
          }

          path = "/*"
        }
      }
    }
  }
}

resource "kubernetes_secret" "bundle_creds_secret" {
  # secert created only if fdi_instance variable is set to true
  count = var.fdi_instance ? 1 : 0

  metadata {
    name      = "bundle-secret"
    namespace = var.namespace
  }

  data = {
    bundle-storage-account = var.bundle_storage_account
    azure-storage-service-version = var.azure_storage_service_version
    tenant_id = var.tenant_id
    client_id = var.client_id
    client_secret = var.client_secret
    bundle_file_path = var.bundle_file_path
  }
}

resource "vault_mount" "minio_mount" {
  path = replace(replace(var.namespace, "-", "_"), "_system", "")
  type = "minio"
}

resource "vault_generic_secret" "minio_config" {
  path = "${vault_mount.minio_mount.path}/config"

  data_json = <<EOT
{
  "endpoint": "minio-gateway.${var.namespace}:9000",
  "accessKeyId": "${random_password.minio_gateway_access_key.result}",
  "secretAccessKey": "${random_password.minio_gateway_secret_key.result}",
  "useSSL": false
}
EOT
}

# READ ALL
resource "vault_generic_secret" "minio_role_read_all" {
  path = "${vault_mount.minio_mount.path}/roles/read-all"

  data_json = <<EOT
{
  "policy": "readonly"
}
EOT
}


resource "kubectl_manifest" "gateway_application" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${var.namespace}
  namespace: ${var.argocd_namespace}
spec:
  project: default
  destination:
    namespace: ${var.argocd_namespace}
    server: https://kubernetes.default.svc
  source:
    repoURL: ${var.argocd_repo_url}
    targetRevision: ${var.argocd_target_revision}
    path: ${var.argocd_folder}
    kustomize:
      version: v4.4.0
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
}
