###########################################################
# ArgoCD Operator
###########################################################
# Argo CD Operator manages the full lifecycle for Argo CD
# and it's components
###########################################################

##
## ArgoCD Operator
##
resource "kubernetes_namespace" "argocd_operator_system" {
  metadata {
    name = "argocd-operator-system"

    labels = {
      "istio-injection"                 = "enabled"
      "namespace.statcan.gc.ca/purpose" = "daaas"
    }
  }
}

module "namespace_argocd_operator_system" {
  source = "git::https://github.com/canada-ca-terraform-modules/terraform-kubernetes-namespace.git?ref=v2.2.0"

  name = kubernetes_namespace.argocd_operator_system.id
  namespace_admins = {
    users  = []
    groups = ["XXX"]
  }

  # CI/CD
  ci_name = "ci"

  # Image Pull Secret
  enable_kubernetes_secret = 0

  # Dependencies
  dependencies = []
}

##
## Deploy ArgoCD Operator and Projects
##
module "argocd_operator" {
  source = "git::https://github.com/canada-ca-terraform-modules/terraform-kubernetes-argocd-operator.git?ref=v1.0.1"

  chart_version   = "0.0.5"
  helm_repository = "https://statcan.github.io/charts"
  helm_namespace  = kubernetes_namespace.argocd_operator_system.id

  argocd_projects = [
    {
      name           = "daaas-system"
      namespace      = "daaas-system"
      classification = "unclassified"
      spec = {
        kustomizeBuildOptions = "--load_restrictor LoadRestrictionsNone",
        oidcConfig = {
          name         = "daaas-system"
          issuer       = "https://login.microsoftonline.com/XXXX/v2.0"
          clientID     = "XXXX"
          clientSecret = var.argocd_operator_client_secret
          requestedIDTokenClaims = {
            groups = {
              essential = true
            }
          }
          requestedScopes = ["openid", "profile", "email"]
        },
        rbac = {
          defaultPolicy = "role:readonly"
          policy        = <<EOT
            p, role:org-admin, applications, *, */*, allow
            p, role:org-admin, clusters, get, *, allow
            p, role:org-admin, repositories, get, *, allow
            p, role:org-admin, repositories, create, *, allow
            p, role:org-admin, repositories, update, *, allow
            p, role:org-admin, repositories, delete, *, allow
            g, "AAD-GROUP-OBJECT-ID", role:org-admin
          EOT
          scopes        = "[groups]"
        },
        server = {
          autoscale = {
            enabled = true
          }
          host     = "daaas-system-argocd.aaw.example.ca"
          insecure = true
        }
      }
    }
  ]
}

resource "kubectl_manifest" "platform_project" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: platform
  namespace: daaas-system
spec:
  clusterResourceWhitelist:
  - group: '*'
    kind: '*'
  destinations:
  - namespace: '*'
    server: '*'
  sourceRepos:
  - '*'
YAML
}

resource "kubectl_manifest" "daaas_system" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: aaw-daaas-system
  namespace: daaas-system
spec:
  project: platform
  destination:
    namespace: daaas-system
    name: in-cluster
  source:
    repoURL: 'https://github.com/StatCan/aaw-argocd-manifests'
    path: daaas-system
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


resource "kubectl_manifest" "statcan_system" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: aaw-statcan-system
  namespace: daaas-system
spec:
  project: platform
  destination:
    namespace: daaas-system
    name: in-cluster
  source:
    repoURL: 'https://github.com/StatCan/aaw-argocd-manifests'
    path: statcan-system
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
