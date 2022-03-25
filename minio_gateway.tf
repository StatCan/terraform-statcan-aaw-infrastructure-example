##
## Minio Gateway Instances
##

locals {
  minio_instances = {
    standard = {
      namespace       = "minio-gateway-standard-system"
      storage_account = "mg-standard"
      boathouse       = true
    }
    premium = {
      namespace       = "minio-gateway-premium-system"
      storage_account = "mg-premium"
      boathouse       = true
    }
    protected = {
      namespace       = "minio-gateway-protected-b-system"
      storage_account = "mg-protb"
      boathouse       = false
    }
  }
  minio_read_instances = {
    standard = {
      namespace       = "minio-gateway-standard-ro-system"
      storage_account = "mg-standard"
      boathouse       = true
    }
    premium = {
      namespace       = "minio-gateway-premium-ro-system"
      storage_account = "mg-premium"
      boathouse       = true
    }
  }
  minio_oidc_instances = {
    standard = {
      namespace       = "minio-gateway-standard-oidc-system"
      storage_account = "mg-standard"
    }
    premium = {
      namespace       = "minio-gateway-premium-oidc-system"
      storage_account = "mg-premium"
    }
  }
}

module "minio_gateway_storage_account" {

  for_each = local.minio_instances

  source = "git::https://github.com/StatCan/terraform-azurerm-storage-account.git?ref=v1.0.0"

  name                = "${var.prefix}-sa-${each.value.storage_account}"
  location            = var.location
  resource_group_name = azurerm_resource_group.daaas_services.name
  tags                = var.tags

  ip_rules                   = var.infrastructure_authorized_ip_ranges
  virtual_network_subnet_ids = concat([data.azurerm_subnet.aks_system.id], var.infrastructure_pipeline_subnet_ids)

  account_replication_type = "ZRS"
  containers               = ["shared"]
}

module "minio_gateway" {
  for_each = local.minio_instances

  source = "./modules/minio-gateway"

  storageAccountName = module.minio_gateway_storage_account[each.key].name
  storageAccountKey  = module.minio_gateway_storage_account[each.key].secondary_access_key

  domain            = "aaw.example.ca"
  namespace         = each.value.namespace
  admins            = ["XXXX"]
  ingress_enabled   = false
  boathouse_enabled = each.value.boathouse

  argocd_namespace       = "daaas-system"
  argocd_repo_url        = "https://github.com/statcan/aaw-argocd-manifests.git"
  argocd_folder          = format("storage-system/%s", each.value.namespace)
  argocd_target_revision = "aaw-prod-cc-00"

}

module "minio_gateway_with_oidc" {
  for_each = local.minio_oidc_instances

  source = "./modules/minio-gateway"

  storageAccountName = module.minio_gateway_storage_account[each.key].name
  storageAccountKey  = module.minio_gateway_storage_account[each.key].secondary_access_key

  openid_instance                  = true
  minio_identity_openid_client_id  = var.minio_identity_openid_client_id
  minio_identity_openid_config_url = var.minio_identity_openid_config_url

  domain          = "aaw.example.ca"
  namespace       = each.value.namespace
  admins          = ["XXXX"]
  ingress_enabled = true

  argocd_namespace       = "daaas-system"
  argocd_repo_url        = "https://github.com/statcan/aaw-argocd-manifests.git"
  argocd_folder          = format("storage-system/%s", each.value.namespace)
  argocd_target_revision = "aaw-prod-cc-00"

}


module "minio_gateway_readonly" {
  for_each = local.minio_read_instances

  source = "./modules/minio-gateway"

  # These are reflecting the "minio_gateway" storage accounts
  storageAccountName = module.minio_gateway_storage_account[each.key].name
  storageAccountKey  = module.minio_gateway_storage_account[each.key].secondary_access_key

  domain            = "aaw.example.ca"
  namespace         = each.value.namespace
  admins            = ["XXXX"]
  ingress_enabled   = false
  boathouse_enabled = each.value.boathouse

  argocd_namespace       = "daaas-system"
  argocd_repo_url        = "https://github.com/statcan/aaw-argocd-manifests.git"
  argocd_folder          = format("storage-system/%s", each.value.namespace)
  argocd_target_revision = "aaw-prod-cc-00"

}


resource "kubernetes_ingress" "minio" {
  metadata {
    name      = "minio-gateway"
    namespace = "minio-gateway-standard-oidc-system"
    annotations = {
      "kubernetes.io/ingress.class" = "istio"
    }
  }

  spec {
    rule {
      host = "minio.aaw.example.ca"
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


resource "kubernetes_ingress" "minio_premium" {
  metadata {
    name      = "minio-gateway"
    namespace = "minio-gateway-premium-oidc-system"

    annotations = {
      "kubernetes.io/ingress.class" = "istio"
    }
  }

  spec {
    rule {
      host = "minio-premium.aaw.example.ca"
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
