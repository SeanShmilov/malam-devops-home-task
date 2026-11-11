output "region" {
  description = "AWS Region"
  value       = var.region
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnets" {
  description = "Private Subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_subnets" {
  description = "Public Subnet IDs"
  value       = module.vpc.public_subnets
}

output "cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "ecr_repository_url" {
  description = "URL of the Amazon ECR Repository for demoapp"
  value       = aws_ecr_repository.demoapp.repository_url
}

output "github_actions_role_arn" {
  description = "IAM Role ARN for GitHub Actions Keyless OIDC Authentication"
  value       = aws_iam_role.github_actions.arn
}

output "acm_certificate_arn" {
  description = "ARN of the ACM TLS Certificate"
  value       = aws_acm_certificate.demoapp.arn
}

output "route53_zone_id" {
  description = "Route 53 Hosted Zone ID"
  value       = aws_route53_zone.primary.zone_id
}

