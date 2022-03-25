resource "kubernetes_namespace" "boathouse_system" {
  metadata {
    name = "boathouse-system"

    labels = {
      "namespace.statcan.gc.ca/purpose" = "system"
    }
  }
}

module "namespace_boathouse_system" {
  source = "git::https://github.com/canada-ca-terraform-modules/terraform-kubernetes-namespace.git?ref=v2.2.0"

  name = kubernetes_namespace.boathouse_system.id
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
## Deploy Boathouse
##
resource "helm_release" "boathouse" {
  name       = "boathouse"
  repository = "./charts"
  chart      = "boathouse"
  version    = "0.1.2"
  timeout    = 3600

  namespace = kubernetes_namespace.boathouse_system.id

  values = [<<EOF
# Default values for boathouse.
# This is a YAML-formatted file.
# Declare variables to be passed into your templates.

image:
  repository: "k8scc01covidacr.azurecr.io/boathouse"
  tag: "fcbbab6389e81adf8644a94044d324780e17f2fa"
  pullPolicy: Always
imagePullSecrets:
  - name: "k8scc01covidacr-registry-connection"
EOF
  ]
}
