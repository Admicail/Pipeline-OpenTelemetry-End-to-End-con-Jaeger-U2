variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "project-54ecee29-e768-42f3-977"
}

variable "region" {
  description = "GCP Region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP Zone"
  type        = string
  default     = "us-central1-a"
}

variable "cluster_name" {
  description = "GKE Cluster name"
  type        = string
  default     = "otel-cluster"
}

variable "registry_name" {
  description = "Artifact Registry repository name"
  type        = string
  default     = "otel-registry"
}
