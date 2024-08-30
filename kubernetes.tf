provider "kubernetes" {
    config_path = "${local_file.kubernetes_config.filename}"  
}

resource "kubernetes_namespace" "argocd" {
    metadata {
    name = "argocd"
    }
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

