terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_artifact_registry_repository" "otel_registry" {
  location      = var.region
  repository_id = var.registry_name
  format        = "DOCKER"
}

resource "google_container_cluster" "otel_cluster" {
  name     = var.cluster_name
  location = var.zone

  remove_default_node_pool = true
  initial_node_count       = 1

  deletion_protection = false
}

resource "google_container_node_pool" "otel_nodes" {
  name       = "otel-node-pool"
  cluster    = google_container_cluster.otel_cluster.name
  location   = var.zone
  node_count = 2

  node_config {
    machine_type = "e2-standard-2"
    disk_size_gb = 50

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
