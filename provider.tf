terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}

# Definir el clúster de Kubernetes
resource "digitalocean_kubernetes_cluster" "taller-demo" {
  name    = "cluster-taller-demo"
  region  = "nyc1"
  version = "1.24.10-do.0"

  node_pool {
    name       = "demo-pool"
    size       = "s-1vcpu-2gb"
    node_count = 3
  }
}

# Salidas
output "kubeconfig" {
  value = digitalocean_kubernetes_cluster.my_cluster.kube_config[0].raw_config
  sensitive = true
}
