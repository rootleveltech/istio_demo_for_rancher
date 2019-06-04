####################################################################
# Setup for External DNS
####################################################################

resource "google_service_account" "dns" {
  account_id   = "${var.env}-external-dns-rw"
  display_name = "${var.env} External DNS-ReadWrite"
  project      = "${var.project}"
}

resource "google_project_iam_member" "dns" {
  project = "${var.project}"
  role    = "roles/dns.admin"
  member  = "serviceAccount:${google_service_account.dns.email}"
}

resource "google_service_account_key" "dns" {
  service_account_id = "${google_service_account.dns.name}"
}

resource "kubernetes_secret" "external_dns" {
  metadata {
    name      = "external-dns-service-account"
    namespace = "${kubernetes_namespace.system.metadata.0.name}"
  }

  data {
    credentials.json = "${base64decode(google_service_account_key.dns.private_key)}"
  }
}

resource "kubernetes_secret" "istio_cert_manager" {
  metadata {
    name      = "istio-cert-manager-credentials"
    namespace = "${kubernetes_namespace.istio_system.metadata.0.name}"
  }

  data {
    gcp-dns-admin.json = "${base64decode(google_service_account_key.dns.private_key)}"
  }
}
