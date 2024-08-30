#resource "null_resource" "install_argocd" {
#  depends_on = [digitalocean_kubernetes_cluster.cluster_taller_demo]  # Asegúrate de que el clúster esté creado antes de ejecutar las tareas

#  provisioner "local-exec" {
#    command = <<EOT
#      kubectl create namespace argocd
#      kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
#    EOT
#  }
#}

#data "digitalocean_kubernetes_cluster" "get-name" {
#  depends_on = [digitalocean_kubernetes_cluster.cluster_taller_demo]
#  name = "cluster1"
#}


#provider "kubernetes" {
#  host  = data.digitalocean_kubernetes_cluster.get-name.endpoint
#  token = data.digitalocean_kubernetes_cluster.get-name.kube_config[0].token
#  cluster_ca_certificate = base64decode(
#    data.digitalocean_kubernetes_cluster.get-name.kube_config[0].cluster_ca_certificate
#  )
#}

#output "kubeconfig" {
#  value = data.digitalocean_kubernetes_cluster.cluster_taller_demo.kube_config[0].raw_config
#  sensitive = true
#}