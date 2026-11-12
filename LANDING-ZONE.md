# Part 4: AWS Landing Zone Architecture

## 1. Landing Zone & Account Structure
- **What it is:** A secure, multi-account AWS environment managed centrally with AWS Control Tower.
- **Why split accounts:** Limits blast radius if breached, isolates service quotas, and tracks costs cleanly.
- **Account Types:**
  - *Management:* Billing, organization hierarchy, and Service Control Policies (SCPs) only.
  - *Log Archive & Security:* Tamper-proof audit logs (S3) and threat detection (GuardDuty, Security Hub).
  - *Network:* Central ingress (WAF/ALB), Transit Gateway (TGW), and centralized internet egress.
  - *Shared Services:* CI/CD runners, container registries, and internal tooling.
  - *Workload:* Isolated application VPC with private subnets for EKS.

## 2. Ingress & Request Flow
- **Flow:** User opens https://demoapp.com → Network ALB terminates TLS → forwards over Transit Gateway directly to private EKS pod IPs.

## 3. Network Changes (Standalone vs. Landing Zone)
| Dimension | Standalone VPC (Part 1) | Landing Zone Workload VPC |
|---|---|---|
| **Subnets** | Public & Private across 3 AZs | **Private subnets only** (No IGW) |
| **NAT Gateway** | Dedicated per VPC ($33/mo) | **Central egress via Transit Gateway** |
| **CIDR** | Default `10.0.0.0/16` | **Non-overlapping** (e.g., `10.50.0.0/20`) |
| **Image Pulls** | Over public internet via NAT | **Local VPC Endpoints (PrivateLink)** |

- **Bonus in code:** Implemented private subnets and VPC Endpoints for S3 and ECR in `terraform/vpc.tf`.

## 4. Guardrails & Policy as Code
- **Mandatory Tags:** `environment`, `owner`, and `cost_center` set on all resources via `default_tags` in `terraform/providers.tf`.
- **SCP Rejection:** Missing tags trigger an `AccessDenied` from SCPs during `terraform apply`, breaking provisioning mid-run.
- **Policy as Code:** Checkov runs in CI as a hard gate (`soft_fail: false`) with documented baseline skips in `.github/workflows/terraform.yml`.

## 5. FinOps & Cost Optimization
| Component | Specification | Monthly Cost |
|---|---|---|
| **EKS Control Plane** | 1 Managed Cluster | $73.00 |
| **Worker Nodes & Storage** | 2x `t3.small` + 40GB `gp3` EBS | $33.57 |
| **Application Load Balancer** | 1 ALB (~15 LCU-hrs/day) | $22.20 |
| **Standalone NAT Gateway** | 1 NAT GW + data transfer | $33.75 |
| **ECR Storage** | 15 images (~5 GB) | $0.50 |
| **Total Standalone Cost** | | **~$163.02 / mo** |

- **Karpenter Autoscaling:** Dynamically provisions right-sized Spot/On-Demand nodes, bin-packs pods, and consolidates empty nodes to eliminate idle waste.
- **Cut Dev Costs:** Use Spot instances (-70%), scale pods to zero off-hours (-70%), drop dedicated NAT.
- **Strictly Refused in Prod:** 100% Spot (eviction risk), single-AZ (SPOF risk), scale-to-zero (production needs 24/7 uptime).
- **Allocation Tags:** Maps AWS bills directly to team cost centers and catches untagged runaway sandbox spend.

## 6. Cross-Account CI/CD Pipeline
- **No Static Keys:** CI runners in Shared Services use keyless OIDC and `sts:AssumeRole` to deploy into Workload accounts.
- **Bonus in code:** Implemented `demoapp-dev-cross-account-deployer-role` with `sts:ExternalId` in `terraform/cross-account-role.tf`.

## 7. AI Reflection & Verification
- **Prompts Used:** Asked AI for cross-account EKS ingress architectures.
- **Kept:** Transit Gateway topology and multi-account boundary separation.
- **Fact-Checked:** AI suggested complex VPC peering; official AWS EKS docs confirmed target type `ip` routes directly over Transit Gateway.
