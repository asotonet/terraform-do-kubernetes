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

#  provisioner "local-exec" {
#    command = "echo ${self.triggers.ip} > /tmp/argocd_lb_ip"
#  }
  
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


#  provisioner "local-exec" {
#    command = "echo ${self.triggers.ip} > /tmp/nginx_lb_ip"
#  }
  
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
  value = "${null_resource.wait_for_nginx_lb_ip.triggers.ip}"
}

# Output para mostrar la IP del LoadBalancer
output "service_argocd_loadbalancer_ip" {
  value = "${null_resource.wait_for_argocd_lb_ip.triggers.ip}"
}