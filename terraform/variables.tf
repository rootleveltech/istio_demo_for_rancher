variable "env" {
  default = "prd"
}

variable "gcp_credentials_json" {
  description = "GCP Credentials Json to allow access to GCP, I use a symlink"
  default = "credentials-braden-rancher-demo.json"
}

variable "project" {
  description = "The GCP Project to create Terraform Resources in"
  default = "braden-rancher-demo"
}

variable "region" {
  description = "The region in which to create the Kubernetes cluster. Must match the zones"
  default     = "us-central1"
}

variable "zones" {
  type        = "list"
  description = "The zone in which to create the Kubernetes cluster. Must match the region"
  default     = ["us-central1-a", "us-central1-b", "us-central1-c"]
}

######################################################################
# GKE
######################################################################
variable "gke_autoscaling_node_count_init" {
  description = "Initial Node Count Per Zone"
  default = "1"
}

variable "gke_autoscaling_node_count_min" {
  description = "Minimum Node Count Per Zone"
  default = "1"
}

variable "gke_autoscaling_node_count_max" {
  description = "Max Node Count Per Zone"
  default = "3"
}

variable "gke_auto_repair" {
  default = "true"
}

variable "gke_auto_upgrade" {
  default = "true"
}

variable "gke_node_machine_type" {
  default = "n1-standard-2"
}

