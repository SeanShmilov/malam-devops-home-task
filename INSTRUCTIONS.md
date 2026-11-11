# Home Exercise: Basic Kubernetes CI/CD & AWS Landing Zone

## General Notes & Guidelines
* **Purpose:** Gain familiarity with your way of thinking, approach to new problems, and ability to design and implement DevOps solutions.
* **Effort & Quality:** Invest only as much time as you can and wish to. Focus on efficient, readable, and well-designed code.
* **Assistance Policy:** Any source of assistance is permitted except for forwarding any part of this document to a third party.
* **Simplicity:** Use the tools and languages of your choice, keeping solutions as simple as possible.
* **Environment:** Implement using a cloud provider of your choice (AWS / EKS is preferred) or on your local machine.

---

## Part 1: Provision a Kubernetes Cluster (IaC with Terraform)
### Objective & Requirements
* Provision and configure a Kubernetes cluster using Infrastructure as Code (IaC) with **Terraform**.
* Prefer managed Kubernetes services (e.g., **AWS EKS**).
* **VPC Architecture:**
  * Create VPC following AWS best practices (multi-AZ, public/private subnets, proper CIDR).
  * Configure ingress and egress communication.
* **Git & Automation Pipeline:**
  * Save Terraform code in Git.
  * Create an automated pipeline (e.g., GitHub Actions) to validate and deploy Terraform on commit or Pull Request.

---

## Part 2: Deploy the Demo Application to the Cluster
### Objective & Requirements
* **Application Source:** [https://github.com/dandolinsky1/malamhomework.git](https://github.com/dandolinsky1/malamhomework.git)
* **Containerization:**
  * Create a production-ready `Dockerfile` (Docker preferred).
* **Helm Chart:**
  * Create a Helm chart for the application and deploy it to Kubernetes.
* **Networking & Exposure:**
  * Publish the application using an **AWS Load Balancer** (ALB / Ingress).
  * Make the application accessible from outside the cluster using the DNS: `demoapp.com` (using a local hosts file is acceptable, internal DNS service like Route 53 preferred).
  * Use TLS certificate access (e.g., AWS Certificate Manager / ACM).
* **Git Strategies:**
  * Manage multiple branches with branch protection/policies and clean Git branching architecture.

### Delivery
* Link to Git repository.
* Screenshot of the application website (including the URL used).

---

## Part 3: Configure CI/CD for the Application
### Objective & Requirements
* Configure a complete CI/CD pipeline to test, build, scan, and deploy application changes automatically.
* Use best-practice methodologies and tooling (e.g., GitHub Actions, Trivy security scanning, automated tagging, Helm/GitOps deploy).

### Delivery
* Link to Git repository with CI/CD workflows and deployment configurations.

---

## Part 4: Deploying the Same Application Inside an AWS Landing Zone

### Context & Scenario
Parts 1–3 assume a single AWS account. In enterprise organizations, workloads run inside an **AWS Landing Zone** managed centrally (AWS Control Tower / Landing Zone Accelerator).
* **Central Network Account:** Owns internet ingress (CloudFront, WAF, shared ALB) and inter-account connectivity (AWS Transit Gateway with centralized egress to the internet).
* **Shared Services Account:** Hosts CI/CD runners, container registries, and shared tooling.
* **Workload Account (Your App):** Contains a dedicated VPC with **private subnets only** (no IGW, no NAT Gateway of its own). All internet-bound traffic routes via Transit Gateway.
* **Organization Guardrails:** SCP/Tagging policy requiring mandatory tags: `environment`, `owner`, and `cost_center` on every resource, blocking creation outside one approved region.

---

### Tasks

#### 1. Research (Max 1 page)
* In your own words, explain what an AWS Landing Zone is and why organizations split workloads across multi-account structures.
* Describe typical account types (e.g., Management, Log Archive, Security/Audit, Network, Shared Services, Workload).
* List references and sources used.
* *AI Reflection:* Detail any AI prompts used, what was kept, and at least one item double-checked against official AWS documentation.

#### 2. Placement Diagram & Request Flow
* Create an architectural diagram illustrating:
  * EKS cluster, Workload VPC, shared Load Balancer, Route 53 DNS for `demoapp.com`, and ACM TLS certificate.
  * Browser-to-pod packet/request flow across accounts.
* Provide a concise ~half-page explanation stating all design assumptions.

#### 3. Network Changes
* Compare the Part 1 standalone VPC with the Landing Zone workload VPC.
* Detail 3–5 architectural changes needed in Terraform (CIDR non-overlapping design, private-only node subnets, routing through TGW, VPC Interface Endpoints for ECR/S3/EC2/Kube API, shared ALB ingress routing).
* **Bonus:** Implement two changes in code (e.g., private-only node subnets + VPC Endpoints for ECR & S3).

#### 4. Guardrails & Policy as Code
* Add required mandatory tags (`environment`, `owner`, `cost_center`) to all Terraform resources (e.g., via AWS provider `default_tags`).
* Explain what happens to the CI/CD pipeline when a resource misses a tag and an SCP rejects it.
* Select a Policy-as-Code tool (e.g., Checkov, TFLint, Conftest/OPA), justify your selection, and define where in the pipeline it should run.
* **Bonus:** Wire the policy-as-code check into the Part 1 pipeline, demonstrating failing and passing runs.

#### 5. FinOps & Cost Optimization
* Estimate monthly cost of Parts 1–3 using the AWS Pricing Calculator (EKS control plane, worker nodes, ALB, NAT/egress, data transfer) formatted as a cost breakdown table.
* Answer the following FinOps questions:
  1. Which 3 changes would cut dev environment costs the most (Spot instances, scheduling/scaling to zero after hours, right-sizing/smaller instances, single-AZ, ephemeral teardowns)?
  2. Which changes would you strictly refuse in Production, and why?
  3. How do allocation tags (`environment`, `owner`, `cost_center`) enable finance teams to track and attribute spend?

#### 6. Pipeline Credentials Across Accounts
* Explain how a CI runner in Shared Services deploys into the Workload account securely without long-lived AWS keys (AWS IAM Role Chaining / AssumeRole with least privilege and external ID / OIDC).
* **Bonus:** Implement cross-account IAM role assuming logic in code/pipeline.

---

### Part 4 Delivery
* `LANDING-ZONE.md` in repository containing answers to Tasks 1–6, diagram, FinOps cost table, and "How I Worked" section.
* Bonus code referenced from the document.

