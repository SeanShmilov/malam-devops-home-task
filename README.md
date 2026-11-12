# DevOps Home Task: EKS, GitOps, CI/CD & Kubernetes Deployment

This repository contains the complete implementation for the DevOps Home Exercise (Parts 1 to 4), encompassing Infrastructure as Code (Terraform), Containerization, Helm packaging, GitHub Actions CI/CD pipelines, and enterprise AWS Landing Zone architecture.

---

## 📁 Repository Structure

```text
├── .github/
│   └── workflows/
│       ├── terraform.yml       # Part 1: Automated Terraform linting, Checkov scan & deployment
│       └── app-ci-cd.yml       # Part 3: Test, build, Trivy scan, ECR push & Helm deploy
├── app/
│   ├── Dockerfile              # Multi-stage, non-root production Dockerfile
│   ├── primes.js               # Core prime calculator logic
│   ├── server.js               # Express HTTP server
│   ├── index.html              # Web UI
│   └── spec/                   # Jasmine unit test specifications
├── helm/
│   └── demoapp/                # Part 2: Production-grade Helm chart
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/          # Deployment, Service, Ingress (ALB), HPA, ServiceAccount
├── terraform/                  # Part 1: Modular Infrastructure as Code
│   ├── providers.tf            # AWS, Helm, Kubernetes providers
│   ├── variables.tf            # Input variables & cluster configuration
│   ├── vpc.tf                  # Multi-AZ VPC + NAT Gateway
│   ├── eks.tf                  # AWS EKS (v1.31) with AL2023 Managed Node Groups
│   ├── ecr.tf                  # ECR repository with scan-on-push & lifecycle expiration
│   ├── alb-controller.tf       # AWS Load Balancer Controller Helm release & Pod Identity
│   ├── alb-controller-policy.json
│   ├── github-oidc.tf          # Keyless GitHub Actions OIDC Provider & IAM Role
│   ├── acm.tf                  # Route 53 zone & ACM TLS certificate (demoapp.com)
│   ├── cross-account-role.tf   # Part 4 (Bonus): Cross-account IAM role for Shared Services CI
│   └── outputs.tf              # Infrastructure endpoints and ARNs
├── docs/
│   └── GIT_STRATEGY.md         # Part 2: Git branching strategy and repository policies
├── LANDING-ZONE.md             # Part 4: Enterprise AWS Landing Zone architecture & FinOps
└── INSTRUCTIONS.md             # Original exercise instructions and prompt guidelines
```

---

## 🚀 Overview of Parts

### Part 1: Infrastructure as Code (Terraform)
* **VPC:** Multi-AZ (3 AZs) with public subnets for ingress/NAT and private subnets for compute. Nodes never receive public IPs.
* **EKS Cluster:** Kubernetes v1.31 running Amazon Linux 2023 (`AL2023_x86_64_STANDARD`) on cost-efficient `t3.small` nodes with Prefix Delegation enabled for maximum pod density.
* **Ingress Controller:** AWS Load Balancer Controller installed via Helm with EKS Pod Identity Association.
* **Security & Auth:** Keyless AWS IAM OIDC federation for GitHub Actions (no permanent AWS credentials).
* **CI/CD:** [`.github/workflows/terraform.yml`](.github/workflows/terraform.yml) automatically runs format checks, validation, and Checkov policy scanning.

### Part 2: Application Containerization & Helm Chart
* **Containerization:** Multi-stage `Dockerfile` with `dumb-init` process supervisor, running as a non-root user (`node`).
* **Helm Chart:** Fully templated under `helm/demoapp` with liveness/readiness probes, resource limits/requests, HPA autoscaling, and ALB Ingress configured for `demoapp.com` with TLS termination via ACM.
* **Git Architecture:** Detailed in [`docs/GIT_STRATEGY.md`](docs/GIT_STRATEGY.md) with Trunk-Based branching and protected `main` branch policies.
* **Website Verification:** Application live on AWS EKS, exposed via AWS ALB with TLS termination:

  ![DemoApp Website Screenshot](docs/screenshot.png)

#### DNS & Endpoint Verification
Per `INSTRUCTIONS.md` (Part 2), external traffic routes to `demoapp.com` via the AWS Application Load Balancer:

```bash
# 1. Retrieve the ALB hostname provisioned by the AWS Load Balancer Controller
ALB_DNS=$(kubectl get ingress demoapp -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# 2. Resolve ALB IP and add mapping to /etc/hosts
ALB_IP=$(dig +short $ALB_DNS | head -n 1)
echo "$ALB_IP demoapp.com" | sudo tee -a /etc/hosts

# 3. Verify TLS termination and routing (returns HTTP/2 200)
curl -kv https://demoapp.com/isPrime/11
```

### Part 3: Continuous Integration & Deployment Pipeline
* Pipeline definition in [`.github/workflows/app-ci-cd.yml`](.github/workflows/app-ci-cd.yml) consists of 5 automated stages:
  1. **Unit Tests:** Executes Jasmine test suite (`npm test`).
  2. **Docker Build:** Validates container build via Docker Buildx.
  3. **Security Vulnerability Scan:** Aqua Trivy scans the container image, failing the build on unfixed `CRITICAL` or `HIGH` vulnerabilities.
  4. **ECR Push (Main only):** Authenticates via OIDC and pushes immutable tagged images (`1.0.0-<git-sha>`). The mutable `:latest` tag is intentionally omitted to avoid overwrite collisions with ECR tag immutability (`image_tag_mutability = "IMMUTABLE"`).
  5. **EKS Deploy (Main only):** Deploys the application to the cluster using Helm with zero downtime.

### Part 4: AWS Landing Zone Architecture & Multi-Account Deployment
* Full technical architectural design, diagrams, and operational teardowns delivered in [`LANDING-ZONE.md`](LANDING-ZONE.md):
  1. **Landing Zone Research:** Multi-account organization strategy, blast-radius isolation, and account taxonomy (Management, Security/Audit, Log Archive, Core Network, Shared Services, Workload).
  2. **Placement Diagram & Flow:** Mermaid diagram illustrating external client ingress via Central Network WAF/ALB, Transit Gateway (TGW) routing, and private pod delivery.
  3. **Network Architecture:** Comparative matrix of standalone VPC vs. Landing Zone Workload VPC (private-only subnets, centralized egress, and local VPC Endpoints).
  4. **Guardrails & Policy-as-Code:** Organization SCPs with mandatory tags (`environment`, `owner`, `cost_center`) enforced via AWS provider `default_tags` and Checkov automated scanning.
  5. **FinOps & Cost Optimization:** Monthly AWS cost breakdown table (~$163.02/mo) and actionable optimization levers (Spot instances, scheduled scaling, single-AZ dev environments) saving up to 70% in non-production.
  6. **Cross-Account CI/CD Security (Bonus Code):** Keyless cross-account deployment design via STS `AssumeRole` and least-privilege scoping, implemented in [`terraform/cross-account-role.tf`](terraform/cross-account-role.tf).

---

## 🛠️ Local Verification Commands

Validate the codebase locally without cloud deployment:

```bash
# 1. Run Application Unit Tests
cd app && npm test

# 2. Lint Helm Chart Templates
helm lint helm/demoapp
helm template demoapp helm/demoapp

# 3. Format & Validate Terraform
cd terraform
terraform fmt -check
terraform init -backend=false
terraform validate
```
