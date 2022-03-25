###########################################################
# ECK Operator
###########################################################
# Orchestrate Elasticsearch, Kibana, APM Server, Enterprise
# Search, and Beats on Kubernetes
###########################################################

##
## ECK Operator
##
resource "kubernetes_namespace" "eck_operator_system" {
  metadata {
    name = "eck-operator-system"

    labels = {
      "istio-injection"                 = "enabled"
      "namespace.statcan.gc.ca/purpose" = "daaas"
    }
  }
}

module "namespace_eck_operator_system" {
  source = "git::https://github.com/canada-ca-terraform-modules/terraform-kubernetes-namespace.git?ref=v2.2.0"

  name = kubernetes_namespace.eck_operator_system.id
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

##
## Deploy ECK Operator and Instances
##
module "eck_operator" {
  source = "git::https://github.com/StatCan/terraform-kubernetes-elastic-cloud.git?ref=v2.x"

  chart_version   = "1.6.0"
  helm_repository = "https://helm.elastic.co"
  helm_namespace  = kubernetes_namespace.eck_operator_system.id
}
