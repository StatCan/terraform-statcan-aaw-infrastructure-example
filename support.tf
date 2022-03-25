// Support
// This file defines support-related resources

// profile-support-global
// Purpose: When granted this role, the entities
// will be able to provide general support to users.
// These provide access to global-level resources.
resource "kubernetes_cluster_role" "profile_support_global" {
  metadata {
    name = "profile-support-global"
  }

  rule {
    api_groups = [""]
    resources  = ["nodes"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["kubeflow.org"]
    resources  = ["profiles"]
    verbs      = ["get", "list", "watch", "create", "delete", "patch", "update"]
  }
}

resource "kubernetes_cluster_role_binding" "profile_support_global" {
  metadata {
    name = "profile-support-global"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.profile_support_global.metadata.0.name
  }

  # DAaaS-AAW-Support
  subject {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Group"
    name      = "468415c1-d3c2-4c7c-a69d-38f3ce11d351"
  }
}

// profile-support
// Purpose: When granted this role, the entities
// will be able to provide general support to users.
// If direct access to a resource is required (like a Pod),
// then the supporter will need to be added as a
// Contributor on the namespace.
resource "kubernetes_cluster_role" "profile_support" {
  metadata {
    name = "profile-support"
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "statefulsets", "replicasets"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "services", "endpoints", "persistentvolumeclaims", "resourcequotas", "events"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["rbac.authorization.k8s.io"]
    resources  = ["roles"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["rbac.authorization.k8s.io", "rbac.istio.io"]
    resources  = ["rolebindings", "servicerolebindings"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  rule {
    api_groups     = ["rbac.authorization.k8s.io"]
    resources      = ["clusterroles"]
    verbs          = ["bind"]
    resource_names = ["kubeflow-admin", "kubeflow-edit"]
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps", "secrets"]
    verbs      = ["list", "watch"]
  }

  rule {
    api_groups = ["kubeflow.org"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }
}
