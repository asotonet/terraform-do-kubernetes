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

# Variable para almacenar la IP del servicio LoadBalancer de ArgoCD
variable "argocd_ip" {
  description = "IP address of the ArgoCD LoadBalancer service"
  type        = string
  default     = ""
}

# Espera hasta que la IP del LoadBalancer de ArgoCD esté disponible
resource "null_resource" "wait_for_argocd_lb_ip" {
  depends_on = [null_resource.patch_argocd_service_kubectl]

  triggers = {
    ip = data.kubernetes_service.argocd_svc.status[0].load_balancer[0].ingress[0].ip
  }

  provisioner "local-exec" {
    command = "echo ${self.triggers.ip} > /tmp/argocd_lb_ip"
  }
}

# Se obtiene la información del servicio ArgoCD
data "kubernetes_service" "argocd_svc" {
  metadata {
    name      = "argocd-server"
    namespace = "argocd"
  }
  depends_on = [
    null_resource.patch_argocd_service_kubectl
  ]
}

# Se crea el registro DNS para el LoadBalancer de ArgoCD usando la IP obtenida
resource "digitalocean_record" "argocd_dns" {
  domain = "asntech.lat"
  type   = "A"
  name   = "argocd"

  value = "${null_resource.wait_for_argocd_lb_ip.triggers.ip}"

  depends_on = [
    null_resource.wait_for_argocd_lb_ip
  ]
}

#Clona el repositorio de la APP demo
resource "null_resource" "git_clone_nginx" {
    provisioner "local-exec" {
    command = "git clone https://github.com/asotonet/kubernetes-nginx-demo"
  }

  # Espera a que se halla ejecutado
  depends_on = [
    kubernetes_namespace.argocd
  ]
}

# Se crea el namespace de NGINX
resource "null_resource" "nginx_namespace" {
    provisioner "local-exec" {
    command = "kubectl --kubeconfig=kubeconfig.yaml  apply -f ./kubernetes-nginx-demo/nginx-web-ns.yaml"
  }

  # Espera a que se halla ejecutado
  depends_on = [
    null_resource.git_clone_nginx
  ]
}

# Se crea el deployment de nginx
resource "null_resource" "nginx_deployment" {
    provisioner "local-exec" {
    command = "kubectl --kubeconfig=kubeconfig.yaml  apply -f ./kubernetes-nginx-demo/nginx-web-app.yaml"
  }

  # Espera a que se halla ejecutado
  depends_on = [
    null_resource.nginx_namespace
  ]
}

# Se crea el deployment de nginx
resource "null_resource" "nginx_service" {
    provisioner "local-exec" {
    command = "kubectl --kubeconfig=kubeconfig.yaml  apply -f ./kubernetes-nginx-demo/nginx-web-svc.yaml"
  }

  # Espera a que se halla ejecutado
  depends_on = [
    null_resource.nginx_deployment
  ]
}

# Variable para almacenar la IP del servicio LoadBalancer de NGINX
variable "nginx_ip" {
  description = "IP address of the Nginx LoadBalancer service"
  type        = string
  default     = ""
}

# Espera hasta que la IP del LoadBalancer de NGINX esté disponible
resource "null_resource" "wait_for_nginx_lb_ip" {
  depends_on = [null_resource.nginx_service]

  triggers = {
    ip = data.kubernetes_service.nginx_svc.status[0].load_balancer[0].ingress[0].ip
  }

  provisioner "local-exec" {
    command = "echo ${self.triggers.ip} > /tmp/nginx_lb_ip"
  }
}

# Se obtiene la información del servicio NGINX
data "kubernetes_service" "nginx_svc" {
  metadata {
    name      = "nginx-web-service"
    namespace = "nginx-web-namespace"
  }
  depends_on = [
    null_resource.nginx_service
  ]
}

# Se crea el registro DNS para el LoadBalancer de NGINX usando la IP obtenida
resource "digitalocean_record" "nginx_web_dns" {
  domain = "asntech.lat"
  type   = "A"
  name   = "web"

  value = "${null_resource.wait_for_nginx_lb_ip.triggers.ip}"

  depends_on = [
    data.kubernetes_service.nginx_svc
  ]
}

# Output para mostrar la IP del LoadBalancer
output "service_nginx_loadbalancer_ip" {
  value = data.kubernetes_service.nginx_svc.status[0].load_balancer[0].ingress[0].ip
}

# Output para mostrar la IP del LoadBalancer
output "service_argocd_loadbalancer_ip" {
  value = data.kubernetes_service.argocd_svc.status[0].load_balancer[0].ingress[0].ip
}
