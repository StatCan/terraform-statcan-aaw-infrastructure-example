terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.61.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "=2.0.2"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.11.3"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "=2.1.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
  }
}

provider "azurerm" {
  # skip_provider_registration   = true
  disable_terraform_partner_id = true

  features {}
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.host
  username               = data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.username
  password               = data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.password
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.cluster_ca_certificate)
}

provider "kubectl" {
  host                   = data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.host
  username               = data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.username
  password               = data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.password
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.cluster_ca_certificate)

  load_config_file = false
}

provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.host
    username               = data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.username
    password               = data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.password
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.cluster_ca_certificate)
  }
}
