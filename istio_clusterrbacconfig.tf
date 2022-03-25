# minio_*instances come from minio_gateway.tf
resource "kubectl_manifest" "istio_clusterrbacconfig" {
  yaml_body = <<YAML
apiVersion: rbac.istio.io/v1alpha1
kind: ClusterRbacConfig
metadata:
  name: default
spec:
  exclusion:
    namespaces:
    - aad-pod-identity-system
    - cert-manager-system
    - daaas-system
    - gatekeeper-system
    - istio-operator-system
    - istio-system
    %{for instance in local.minio_instances}
    - ${instance.namespace}
    %{endfor}
    %{for instance in local.minio_read_instances}
    - ${instance.namespace}
    %{endfor}
    %{for instance in local.minio_oidc_instances}
    - ${instance.namespace}
    %{endfor}
    - knative-serving
    - kube-node-lease
    - kube-node-public
    - kube-system
    - kubecost-system
    - kubeflow
    - oauth2-proxy-system
    - prometheus-system
    - statcan-system
    - shared-daaas-system
    - velero-system
    - vault-system
  mode: ON_WITH_EXCLUSION
YAML
}
