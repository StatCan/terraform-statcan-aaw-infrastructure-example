##
## monitoring-system
##
resource "kubernetes_namespace" "monitoring_system" {
  metadata {
    name = "monitoring-system"

    labels = {
      "istio-injection"                                = "enabled"
      "namespace.statcan.gc.ca/purpose"                = "daaas"
      "network.statcan.gc.ca/allow-ingress-controller" = "true"
    }
  }
}

module "namespace_monitoring_system" {
  source = "git::https://github.com/canada-ca-terraform-modules/terraform-kubernetes-namespace.git?ref=v2.2.0"

  name = kubernetes_namespace.monitoring_system.id
  namespace_admins = {
    users = []
    groups = ["XXX"]
  }

  # CI/CD
  ci_name = "ci"

  # Dependencies
  dependencies = []
}

resource "kubectl_manifest" "monitoring_system_application" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: monitoring-system
  namespace: daaas-system
spec:
  project: default
  destination:
    namespace: monitoring-system
    server: https://kubernetes.default.svc
  source:
    repoURL: 'https://github.com/StatCan/aaw-argocd-manifests'
    path: monitoring-system
    targetRevision: "aaw-prod-cc-00"
    directory:
      recurse: true
      jsonnet:
        extVars:
        - name: targetRevision
          value: $ARGOCD_APP_SOURCE_TARGET_REVISION
        - name: folder
          value: $ARGOCD_APP_SOURCE_PATH
        - name: url
          value: $ARGOCD_APP_SOURCE_REPO_URL
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML
}
