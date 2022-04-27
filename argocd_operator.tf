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

locals {
  argocd_projects = [
    {
      name           = "daaas-system"
      namespace      = "daaas-system"
      classification = "protected-b"
      spec = {
        image = {
          repository = "argoproj/argocd"
          tag        = "sha256:0bbcd97134f2d7c28293d4b717317f32aaf8fa816a1ffe764c1ebc390c4646d3"
        },
        kustomizeBuildOptions = "--load-restrictor LoadRestrictionsNone --enable-helm",
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

resource "helm_release" "argocd_operator" {
  name = "argocd-operator"

  repository = "https://statcan.github.io/charts"
  chart      = "argocd-operator"
  version    = "0.1.2"
  namespace  = kubernetes_namespace.argocd_operator_system.id
  timeout    = 1200

  values = [<<EOF
operator:
  clusterDomain: ""
  nsToWatch: "argocd-operator-system,daaas-system"
  nsClusterConfig: "daaas-system"
  image:
    pullPolicy: IfNotPresent
  imagePullSecrets: []
  replicaCount: 1
  securityContext:
    runAsUser: 1000
    runAsGroup: 1000
    runAsNonRoot: true
    fsGroup: 1000
  resources:
    requests:
      cpu: 200m
      memory: 256Mi
      ephemeral-storage: 500Mi

projects:
%{for project in local.argocd_projects~}
  - name: ${project.name}
    namespace: ${project.namespace}
    podLabels:
      data.statcan.gc.ca/classification: ${project.classification}
    spec:
      image: ${project.spec.image.repository}
      version: ${project.spec.image.tag}
      kustomizeBuildOptions: ${project.spec.kustomizeBuildOptions}
      oidcConfig: |
        name: ${project.spec.oidcConfig.name}
        issuer: ${project.spec.oidcConfig.issuer}
        clientID: ${project.spec.oidcConfig.clientID}
        clientSecret: ${project.spec.oidcConfig.clientSecret}
        requestedIDTokenClaims:
          groups:
            essential: ${project.spec.oidcConfig.requestedIDTokenClaims.groups.essential}
        requestedScopes: ${jsonencode(project.spec.oidcConfig.requestedScopes)}
      rbac:
        defaultPolicy: ${project.spec.rbac.defaultPolicy}
        policy: ${jsonencode(project.spec.rbac.policy)}
        scopes: ${jsonencode(project.spec.rbac.scopes)}
      server:
        autoscale:
          enabled: ${project.spec.server.autoscale.enabled}
        host: ${project.spec.server.host}
        insecure: ${project.spec.server.insecure}
%{endfor~}
EOF
  ]
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
    targetRevision: aaw-prod-cc-00
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
    targetRevision: aaw-prod-cc-00
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
