####################################################################
# Namespaces
####################################################################
resource "kubernetes_namespace" "app" {
  metadata {
    labels {
      istio-injection = "enabled"
    }

    name = "${var.env}-app"
  }
}

resource "kubernetes_namespace" "system" {
  metadata {
    name = "${var.env}-system"
  }
}

resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
  }
}
