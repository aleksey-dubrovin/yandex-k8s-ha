/* # Получаем credentials для доступа к кластеру
data "yandex_kubernetes_cluster" "k8s_cluster" {
  cluster_id = yandex_kubernetes_cluster.k8s_cluster.id
}

provider "kubernetes" {
  host                   = data.yandex_kubernetes_cluster.k8s_cluster.master.0.external_v4_endpoint
  cluster_ca_certificate = base64decode(data.yandex_kubernetes_cluster.k8s_cluster.master.0.cluster_ca_certificate)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "yc"
    args        = ["managed-kubernetes", "cluster", "get-credentials", yandex_kubernetes_cluster.k8s_cluster.id, "--folder-id", var.folder_id]
  }
}

provider "helm" {
  kubernetes {
    host                   = data.yandex_kubernetes_cluster.k8s_cluster.master.0.external_v4_endpoint
    cluster_ca_certificate = base64decode(data.yandex_kubernetes_cluster.k8s_cluster.master.0.cluster_ca_certificate)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "yc"
      args        = ["managed-kubernetes", "cluster", "get-credentials", yandex_kubernetes_cluster.k8s_cluster.id, "--folder-id", var.folder_id]
    }
  }
}

# Устанавливаем Cluster Autoscaler через Helm
resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  namespace  = "kube-system"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = var.cluster_autoscaler_version

  set {
    name  = "cloudProvider"
    value = "yandex"
  }

  set {
    name  = "yandexCloud.clusterId"
    value = yandex_kubernetes_cluster.k8s_cluster.id
  }

  set {
    name  = "yandexCloud.folderId"
    value = var.folder_id
  }

  set {
    name  = "autoDiscovery.clusterName"
    value = yandex_kubernetes_cluster.k8s_cluster.name
  }

  set {
    name  = "autoDiscovery.cloudProvider"
    value = "yandex"
  }

  # Исправленный блок nodeSelector
  set {
    name  = "nodeSelector.kubernetes\\.io/os"
    value = "linux"
  }

  depends_on = [
    yandex_kubernetes_cluster.k8s_cluster
  ]
} */