resource "kubectl_manifest" "kube_system_application" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kube-system
  namespace: daaas-system
spec:
  project: default
  destination:
    namespace: kube-system
    server: https://kubernetes.default.svc
  source:
    repoURL: 'https://github.com/StatCan/aaw-argocd-manifests'
    path: kube-system
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
  ignoreDifferences:
    - group: ""
      kind: ConfigMap
      namespace: kube-system
      jsonPointers:
        - /data/kfserving-ingress.override
  syncPolicy:
    automated:
      prune: false
      selfHeal: false
YAML
}
