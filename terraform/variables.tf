variable "region" {
  description = "AWS Region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod) - mandatory Landing Zone tag"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Resource owner team or individual - mandatory Landing Zone tag"
  type        = string
  default     = "devops-team"
}

variable "cost_center" {
  description = "Cost allocation center identifier - mandatory Landing Zone tag"
  type        = string
  default     = "engineering-101"
}

variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
  default     = "demoapp-cluster"
}

variable "cluster_version" {
  description = "Kubernetes Version for EKS"
  type        = string
  default     = "1.31"
}

variable "node_instance_type" {
  description = "EC2 Instance type for worker nodes (t3.small provides cost efficiency for dev/demo workloads)"
  type        = string
  default     = "t3.small"
}

variable "desired_nodes" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "min_nodes" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "max_nodes" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "domain_name" {
  description = "Base domain name for application ingress"
  type        = string
  default     = "demoapp.com"
}

variable "github_repo_filter" {
  description = "GitHub repository filter for OIDC role trust policy (e.g. repo:org/repo:*)"
  type        = string
  default     = "repo:*"
}

