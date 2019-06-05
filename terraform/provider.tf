provider "google" {
  version = "~> 2.7.0"

  credentials = "${pathexpand("${var.gcp_credentials_json}")}"
  project     = "${var.project}"
  region      = "${var.region}"
}

provider "google-beta" {
  version = "~> 2.7.0"

  credentials = "${pathexpand("${var.gcp_credentials_json}")}"
  project     = "${var.project}"
  region      = "${var.region}"
}

data "google_client_config" "default" {}

provider "kubernetes" {
  load_config_file = false

  host = "https://${google_container_cluster.gke.endpoint}"
  token = "${data.google_client_config.default.access_token}"
  cluster_ca_certificate = "${base64decode(google_container_cluster.gke.master_auth.0.cluster_ca_certificate)}"
}
