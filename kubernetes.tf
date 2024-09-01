# Se apunta al archivo kubeconfig.yaml
provider "kubernetes" {
    config_path = "${local_file.kubernetes_config.filename}"  
}

#Se crea el namespace para argocd
resource "kubernetes_namespace" "argocd" {
    metadata {
    name = "argocd"
    }
}

#Se instala argocd
resource "null_resource" "apply_kubectl" {
    provisioner "local-exec" {
    command = "kubectl --kubeconfig=kubeconfig.yaml apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml "
  }

  # Espera a que se cree el namespace
  depends_on = [
    kubernetes_namespace.argocd
  ]
}

#Modifica el tipo de servicio y cambia de tipo cluster a tipo loadbalancer
resource "null_resource" "patch_argocd_service_kubectl" {
    provisioner "local-exec" {
    command = "kubectl --kubeconfig=kubeconfig.yaml  apply -f ./argocd-config/argocd-server-svc.yaml"
  }

  # Espera a que se halla instalado ArgoCD
  depends_on = [
    null_resource.apply_kubectl
  ]
}

/*
#Se obtiene el token admin password para indiicar sesión en Argocd
resource "null_resource" "get_token_password_kubectl" {
    provisioner "local-exec" {
    command = <<EOT
kubectl --kubeconfig=kubeconfig.yaml -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
EOT
  }
  depends_on = [
    null_resource.patch_argocd_service_kubectl
  ]
}
*/

#Se trae los datso del SVC con el nombre "argocd"
data "kubernetes_service" "prueba_svc" {
  metadata {
    name      = "argocd-server"
    namespace = "argocd"
  }
  depends_on = [
     null_resource.patch_argocd_service_kubectl
  ]
}
# Output para mostrar la IP del LoadBalancer
output "service_loadbalancer_ip" {
  value = data.kubernetes_service.prueba_svc.status[0].load_balancer[0].ingress[0].ip
}

#Se crea el registro DNS para el loadbalancer de Argocd a partir de la IP obtenida en el SVC de loadbalancer creado.
resource "digitalocean_record" "argocd_dns" {
  domain = "asntech.lat"
  type   = "A"
  name   = "argocd"

  value = data.kubernetes_service.prueba_svc.status[0].load_balancer[0].ingress[0].ip

  depends_on = [
    null_resource.patch_argocd_service_kubectl
  ]
}
#resource "kubernetes_manifest" "patch_argocd_service" {
#  manifest = {
#    "apiVersion" = "v1"
#    "kind"       = "Service"
##    "metadata" = {
 #     "name"      = "argocd-server"
 #     "namespace" = "${kubernetes_namespace.argocd.metadata[0].name}"
 #   }
#    "spec" = {
#      "type" = "LoadBalancer"
#    }
#  }
#  depends_on = [
##    kubernetes_namespace.argocd
 # ]
#}

