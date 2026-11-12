# ==============================================================================
# Part 4 - Task 6 (Bonus): Cross-Account IAM Role for CI/CD Pipeline
# ==============================================================================
# This role is deployed into the Workload Account (where EKS and demoapp reside).
# It allows CI/CD runners residing in the centralized "Shared Services Account"
# to assume this role with least-privilege permissions to deploy the application,
# without storing long-lived AWS credentials.

variable "shared_services_account_id" {
  description = "AWS Account ID of the Shared Services / CI account (defaults to current account if unspecified)"
  type        = string
  default     = ""
}

variable "ci_runner_role_name" {
  description = "IAM Role name or pattern of CI runners in the Shared Services account"
  type        = string
  default     = "demoapp-cluster-github-actions-role"
}

locals {
  effective_shared_services_account_id = var.shared_services_account_id != "" ? var.shared_services_account_id : data.aws_caller_identity.current.account_id
}

# Trust relationship policy allowing only the specific runner role in Shared Services to assume
data "aws_iam_policy_document" "cross_account_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.effective_shared_services_account_id}:role/${var.ci_runner_role_name}"]
    }

    # Optional: Condition on external ID or source identity for defense in depth
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = ["demoapp-deployment-${var.environment}"]
    }
  }
}

resource "aws_iam_role" "cross_account_deployer" {
  name               = "demoapp-${var.environment}-cross-account-deployer-role"
  description        = "Assumed by Shared Services CI runner to deploy demoapp into the workload cluster"
  assume_role_policy = data.aws_iam_policy_document.cross_account_trust.json
}

# Least-privilege policy: strictly scoped to EKS describe and namespace operations
resource "aws_iam_policy" "cross_account_deployer_policy" {
  name        = "demoapp-${var.environment}-cross-account-deployer-policy"
  description = "Least-privilege permissions required to deploy demoapp via Helm into EKS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EKSClusterAccess"
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = module.eks.cluster_arn
      },
      {
        Sid    = "ECRPushPull"
        Effect = "Allow"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = aws_ecr_repository.demoapp.arn
      },
      {
        Sid    = "ECRAuthToken"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cross_account_deployer" {
  role       = aws_iam_role.cross_account_deployer.name
  policy_arn = aws_iam_policy.cross_account_deployer_policy.arn
}

output "cross_account_deployer_role_arn" {
  description = "IAM Role ARN to be assumed by the Shared Services CI runner"
  value       = aws_iam_role.cross_account_deployer.arn
}

