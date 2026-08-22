variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-2"
}

variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
  default     = "otel-cluster"
}
