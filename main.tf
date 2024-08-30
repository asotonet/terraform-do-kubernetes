# Definir el clúster de Kubernetes
resource "digitalocean_kubernetes_cluster" "cluster_demo" {
  name    = "cluster1"
  region  = "nyc1"
  version = "1.30.4-do.0"

  node_pool {
    name       = "demo-pool"
    size       = "s-1vcpu-2gb"
    node_count = 1
  }
}

output "kubeconfig" {
  value     = "${digitalocean_kubernetes_cluster.cluster_demo.kube_config[0].raw_config}"
  sensitive = true
}