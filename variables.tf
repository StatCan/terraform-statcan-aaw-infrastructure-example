variable "prefix" {
  description = "Prefix of Azure resources"
}

variable "location" {
  description = "Azure region for Azure resources"
}

variable "tags" {
  type        = map(string)
  description = "List of tags to assign to Azure resources"

  default = {}
}

variable "infrastructure_authorized_ip_ranges" {
  type        = list(string)
  description = "Allowed IP addresses for infastructure components."

  default = []
}

variable "infrastructure_pipeline_subnet_ids" {
  type        = list(string)
  description = "Subnet ID of infrastructure pipeline"

  default = []
}

# jFrog

variable "jfrog_join_key" {
  description = "Join key for jFrog Platform"
  sensitive   = true
}

variable "jfrog_master_key" {
  description = "Master key for jFrog Platform"
  sensitive   = true
}

#
# Argo CD
#
variable "argocd_operator_client_secret" {
  description = "Argo CD Operator Client Secret"
  sensitive   = true
}


variable "minio_identity_openid_client_id" {
  description = "MinIO Identity OpenID Cient ID"
}

variable "minio_identity_openid_config_url" {
  description = "MinIO Identity OpenID Config URL"
}



variable "bundle_tenant_id" {
  description = "The directory tenant that you want to request permission from."
  sensitive   = true
}

variable "bundle_client_id" {
  description = "The Application (client) ID that's assigned to your app."
  sensitive   = true
}

variable "bundle_client_secret" {
  description = "The application secret for your app."
  sensitive   = true
}
