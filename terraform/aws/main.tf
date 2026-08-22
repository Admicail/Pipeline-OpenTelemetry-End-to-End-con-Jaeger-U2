terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# ── VPC ──────────────────────────────────────────────────────────────────────
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "otel-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.region}a", "${var.region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = {
    Project     = "otel-pipeline"
    Environment = "aws"
  }
}

# ── EKS Cluster ──────────────────────────────────────────────────────────────
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    otel_nodes = {
      min_size       = 2
      max_size       = 3
      desired_size   = 2
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      labels = {
        Project = "otel-pipeline"
      }
    }
  }

  tags = {
    Project     = "otel-pipeline"
    Environment = "aws"
  }
}

# ── ECR — Repositorios de imágenes Docker ────────────────────────────────────
resource "aws_ecr_repository" "service_a" {
  name                 = "service-a"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Project = "otel-pipeline"
  }
}

resource "aws_ecr_repository" "service_b" {
  name                 = "service-b"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = {
    Project = "otel-pipeline"
  }
}
