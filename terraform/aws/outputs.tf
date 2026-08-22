output "cluster_name" {
  description = "EKS Cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS Cluster endpoint"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "ecr_service_a_url" {
  description = "ECR URL for service-a"
  value       = aws_ecr_repository.service_a.repository_url
}

output "ecr_service_b_url" {
  description = "ECR URL for service-b"
  value       = aws_ecr_repository.service_b.repository_url
}

output "kubectl_command" {
  description = "Command to configure kubectl for EKS"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${var.cluster_name}"
}
