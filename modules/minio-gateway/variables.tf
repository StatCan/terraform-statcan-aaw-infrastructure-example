variable "storageAccountName" {
  description = "Blob Storage account name"
}

variable "storageAccountKey" {
  description = "Blob Storage account key"
}

variable "domain" {
  description = "the URL domain for the ingress (e.g. aaw.cloud.statcan.ca)"
}

variable "namespace" {
  description = "Namespace to create"
  default     = "minio-gateway-system"
}

variable "admins" {
  description = "The Namespace admins"
}

variable "ingress_enabled" {
  description = "Allow ingress to namespace"
  default     = false
}

variable "boathouse_enabled" {
  description = "Whether boathouse needs ingress"
  default     = false
}

variable "argocd_namespace" {
  description = "The namespace to deploy the ArgoCD Application CR to"
}

variable "argocd_repo_url" {
  description = "The ArgoCD Manifests Repo"
  default     = "https://github.com/statcan/aaw-argocd-manifests.git"
}

variable "argocd_folder" {
  description = "The ArgoCD subfolder to deploy"
}

variable "argocd_target_revision" {
  description = "The targetRevision to deploy from the git repo"
}

variable "openid_instance" {
  description = "Whether this instance of MinIO implements OpenID"
  default     = false
}

variable "minio_identity_openid_client_id" {
  description = "MinIO Identity OpenID Cient ID"
  default     = ""
}

variable "minio_identity_openid_config_url" {
  description = "MinIO Identity OpenID Config URL"
  default     = ""
}

variable "fdi_instance" {
  description = "Whether this instance is an FDI instance"
  default     = false
}

variable "bundle_storage_account" {
  description = "The storage account that contains the OPA bundle(s)"
  default     = ""
}

variable "azure_storage_service_version" {
  description = "The Microsoft Azure storage services version"
  default     = ""
}

variable "tenant_id" {
  description = "The directory tenant that you want to request permission from."
  default     = ""
}

variable "client_id" {
  description = "The Application (client) ID that's assigned to your app."
  default     = ""
}

variable "client_secret" {
  description = "The application secret for your app."
  default     = ""
}

variable "bundle_file_path" {
  description = "The bundle file path"
  default     = ""
}

variable "storage_account_rg" {
  description = "Resource group of the storage account."
  default     = ""
}

variable "storage_account_subscription" {
  description = "Subscription of the storage acount."
  default     = "AAW"
}
