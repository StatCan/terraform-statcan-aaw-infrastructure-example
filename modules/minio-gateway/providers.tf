terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "=2.0.2"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.11.3"
    }

    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }

    vault = {
      source  = "hashicorp/vault"
      version = "2.21.0"
    }
  }
}
