resource "google_container_cluster" "gke" {
  name               = "${var.env}-gke"
  location           = "${var.zones[0]}"
  additional_zones    = ["${var.zones[1]}", "${var.zones[2]}"]

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  node_pool {
    name = "default-pool"

    #NOTE: this is per zone, max sure max_node_count is high enough
    #      to account for all zones
    initial_node_count = "${var.gke_autoscaling_node_count_init}"

    autoscaling {
      min_node_count = "${var.gke_autoscaling_node_count_min}"
      max_node_count = "${var.gke_autoscaling_node_count_max}"
    }

    management {
      auto_repair  = "${var.gke_auto_repair}"
      auto_upgrade = "${var.gke_auto_upgrade}"
    }

    node_config {
      machine_type = "${var.gke_node_machine_type}"
      image_type   = "COS"

      oauth_scopes = [
        "compute-rw",
        "storage-ro",
        "logging-write",
        "monitoring",
      ]

      metadata {
        disable-legacy-endpoints = "true"
      }
    }
  }

  timeouts {
    create = "30m"
    update = "40m"
  }
}

resource "null_resource" "configure_gke" {
  triggers = {
    cluster_ca_certificate = "${google_container_cluster.gke.master_auth.0.cluster_ca_certificate}"
  }

  provisioner "local-exec" {
    command = <<EOF
echo "${google_container_cluster.gke.master_auth.0.cluster_ca_certificate}" > /dev/null
gcloud auth activate-service-account --key-file=${pathexpand("${var.gcp_credentials_json}")}
gcloud container clusters get-credentials ${google_container_cluster.gke.*.name[0]} --zone ${var.zones[0]} --project ${var.project}
export CONTEXT=$(kubectl config current-context)
kubectl apply -f ../istio/install/kubernetes/helm/helm-service-account.yaml
helm init --service-account tiller --wait
EOF
  }
}
