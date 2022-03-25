##
## shared-daaas-system
##
resource "kubernetes_namespace" "shared_daaas_system" {
  metadata {
    name = "shared-daaas-system"

    labels = {
      "istio-injection"                                = "enabled"
      "namespace.statcan.gc.ca/purpose"                = "daaas"
      "network.statcan.gc.ca/allow-ingress-controller" = "true"
    }
  }
}

module "namespace_shared_daaas_system" {
  source = "git::https://github.com/canada-ca-terraform-modules/terraform-kubernetes-namespace.git?ref=v2.2.0"

  name = kubernetes_namespace.shared_daaas_system.id
  namespace_admins = {
    users  = []
    groups = ["XXXX"]

  }

  # CI/CD
  ci_name = "ci"

  # Dependencies
  dependencies = []
}

resource "kubectl_manifest" "shared_daaas_system_application" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: shared-daaas-system
  namespace: daaas-system
spec:
  project: default
  destination:
    namespace: shared-daaas-system
    server: https://kubernetes.default.svc
  source:
    repoURL: 'https://github.com/StatCan/aaw-argocd-manifests'
    path: shared-daaas-system
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
