# resource "kubernetes_manifest" "namespace_create" {
#   manifest = {
#     "apiVersion" = "v1"
#     "kind"       = "Namespace"
#     "metadata" = {
#       "labels" = {
#         "env" = var.env
#       }
#       "name" = var.namespace
#     }
#   }
# }

# resource "kubernetes_manifest" "namespace_create" {
#   manifest = {
#     "apiVersion" = "v1"
#     "kind"       = "Namespace"
#     "metadata" = {
#       "name"      = var.namespace
#       "labels" = {
#         env = var.env
#       }
#     }
#   }
# }

resource "kubernetes_manifest" "go_api_deployment" {
  manifest = {
    apiVersion = "apps/v1"
    kind       = "Deployment"
    metadata = {
      name      = var.deployment_name
      namespace = var.namespace
      labels = {
        app = var.app_name
        env = var.env
      }
    }
    spec = {
      replicas = var.replicas_count
      selector = {
        matchLabels = {
          app = var.app_name
        }
      }
      template = {
        metadata = {
          labels = {
            app = var.app_name
          }
        }
        spec = {
          serviceAccountName = var.service_account_name
          containers = [{
            name  = var.app_name
            image = var.image_name
            ports = [{
              containerPort = 8080
              name          = "http"
            }]
            "resources" = {
              "limits" = {
                "cpu"    = "1"
                "memory" = "3Gi"
              }
              "requests" = {
                "cpu"    = "750m"
                "memory" = "2Gi"
              }
            }
          }]
        }
      }
    }
  }

  # depends_on = [kubernetes_manifest.namespace_create]
}

resource "kubernetes_manifest" "go_api_service" {
  manifest = {
    apiVersion = "v1"
    kind       = "Service"
    metadata = {
      "labels" = {
        "env" = var.env
      }
      name      = "${var.deployment_name}-svc"
      namespace = var.namespace
    }
    spec = {
      type = "LoadBalancer"
      ports = [{
        port       = 80
        protocol   = "TCP"
        targetPort = "http"
      }]
      selector = {
        app = var.app_name
      }
    }
  }

  # depends_on = [kubernetes_manifest.namespace_create, kubernetes_manifest.go_api_deployment]
}
