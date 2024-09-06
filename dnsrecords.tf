# Variable para almacenar la IP del servicio LoadBalancer de ArgoCD
variable "argocd_ip" {
  description = "IP address of the ArgoCD LoadBalancer service"
  type        = string
  default     = ""
}


# Espera hasta que la IP del LoadBalancer de ArgoCD esté disponible
resource "null_resource" "wait_for_argocd_lb_ip" {
  depends_on = [time_sleep.time_sleep_for_argolb]

  triggers = {
    ip = data.kubernetes_service.argocd_svc.status[0].load_balancer[0].ingress[0].ip
  }

# Se obtiene la información del servicio ArgoCD
data "kubernetes_service" "argocd_svc" {
  metadata {
    name      = "argocd-server"
    namespace = "argocd"
  }
  depends_on = [
    time_sleep.time_sleep_for_argolb
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

# Output para mostrar la IP del LoadBalancer
output "service_argocd_loadbalancer_ip" {
  value = "${null_resource.wait_for_argocd_lb_ip.triggers.ip}"
}

output "dns_record_output" {
  value = digitalocean_record.argocd_dns
  description = "FQDN del registro DNS creado"
}

##########################################################




################################################################