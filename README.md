
# Terraform DO Kubernetes       
<img alt="Terraform" src="https://www.datocms-assets.com/2885/1629941242-logo-terraform-main.svg" width="600px">


Este repositorio contiene configuraciones de Terraform para desplegar un clúster de Kubernetes en DigitalOcean. La configuración incluye la creación del clúster, los grupos de nodos, y proporciona una salida `kubeconfig` para gestionar el clúster.

## Requisitos previos

Antes de comenzar, asegúrate de tener instalados los siguientes elementos:

- [Terraform](https://www.terraform.io/downloads.html) (versión 0.12+)
- [DigitalOcean CLI (doctl)](https://github.com/digitalocean/doctl) (opcional pero recomendado)
- Una cuenta de DigitalOcean con un token de API

## Diagrama de flujo

````mermaid
graph TD
    A[Desarrollador hace push a GitHub] -->|Trigger| B[GitHub Actions inicia workflow]
    B --> C{Ejecutar pruebas}
    C -->|Fallan| D[Notificar al desarrollador]
    D --> A
    C -->|Pasan| E[Construir imagen Docker]
    E --> F[Subir imagen a DockerHub]
    F --> G[Actualizar manifiesto de Kubernetes en GitHub]
    G --> H[ArgoCD detecta cambios]
    H --> I[ArgoCD compara estado deseado vs actual]
    I --> J[ArgoCD aplica cambios en cluster Kubernetes]
    J --> K[Monitorear despliegue]
    K -->|Éxito| L[Notificar equipo]
    K -->|Fallo| M[Rollback automático y notificar]
    M --> A
````

## Primeros pasos

### Clonar el repositorio

```bash
git clone https://github.com/asotonet/terraform-do-kubernetes.git
cd terraform-do-kubernetes`` 
```
### Configuración

1.  **Token de DigitalOcean:** Actualiza tu archivo `terraform.tfvars` con tu token de API de DigitalOcean.
    

`do_token = "tu_token_de_api_de_digitalocean`
    
4.  **Configuración del Clúster de Kubernetes:** La configuración del clúster se encuentra en el archivo `provider.tf`. Puedes personalizar la versión de Kubernetes, la región y la configuración del grupo de nodos según tus necesidades.
    

### Uso

Para desplegar el clúster de Kubernetes en DigitalOcean, sigue estos pasos:

1.  **Inicializar Terraform:**

    `terraform init` 
    
2.  **Aplicar el Plan de Terraform:**
    
    `terraform apply` 
    
    Revisa el plan y escribe `yes` para confirmar.
    
3.  **Acceder al Clúster de Kubernetes:**
    
    El archivo `kubeconfig` se proporcionará como una salida. Puedes guardarlo en un archivo y usar `kubectl` para interactuar con tu clúster.
    
    `export KUBECONFIG=$(terraform output kubeconfig)
    kubectl get nodes` 

    ````bash
    kubectl --kubeconfig=kubeconfig.yaml get nodes
    ````
4.  **Instalar ArgoCD y crear el loadbalancer:**
    ````bash
    kubectl --kubeconfig=kubeconfig.yaml apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    ````
    Exponemos el puerto del servicio con un balanceador
    ````bash
    kubectl --kubeconfig=kubeconfig.yaml patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
    ````
    Mostramos la contraseña inicial del servicio ArgoCD
    ````bash
    kubectl --kubeconfig=kubeconfig.yaml -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    ````
### Destruir el Clúster

Para eliminar el clúster de Kubernetes y todos los recursos relacionados:

`terraform destroy` 

### Solución de Problemas

-   Si encuentras problemas con la versión de Kubernetes o la API, verifica que la versión especificada en `provider.tf` esté disponible usando `doctl`.
-   Asegúrate de que tu Digital Ocean Token Key esté configurado correctamente para la conexión remota.

### Contribuciones

Siéntete libre de bifurcar este repositorio, hacer cambios y enviar solicitudes de extracción. ¡Las contribuciones son bienvenidas!

### Licencia

Este proyecto está licenciado bajo la Licencia MIT. Consulta el archivo LICENSE para más detalles.
