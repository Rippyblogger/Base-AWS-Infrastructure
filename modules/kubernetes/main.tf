resource "kubernetes_deployment_v1" "go_api_deployment" {

  depends_on = [kubernetes_service_account_v1.app_service_account]
  metadata {
    name = var.deployment_name
    labels = {
      app = var.app_name
      env = var.env
    }
  }

  spec {
    replicas = var.replicas_count

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.app_name
        }
      }

      spec {
        service_account_name = var.service_account_name

        container {
          name  = var.app_name
          image = var.image_name

          port {
            container_port = 8080
            name           = "http"
          }

          readiness_probe {
            http_get {
              path   = "/health"
              port   = 8080
              scheme = "HTTP"
            }
            initial_delay_seconds = 60
            period_seconds        = 10
            timeout_seconds       = 5
            success_threshold     = 1
            failure_threshold     = 3
          }

          resources {
            limits = {
              cpu    = "2"
              memory = "4Gi"
            }
            requests = {
              cpu    = "1"
              memory = "3Gi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "go_api_service" {
  metadata {
    name = "${var.deployment_name}-svc"
    labels = {
      env = var.env
    }
  }

  spec {
    selector = {
      app = var.app_name
    }

    port {
      port        = 80
      target_port = "http"
      protocol    = "TCP"
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_service_account_v1" "app_service_account" {
  metadata {
    name = var.service_account_name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.irsa_role.arn
    }
    labels = {
      app = var.app_name
      env = var.env
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

