# Highly Available 3-Tier Web Application on AWS — Terraform (IaC) Edition

![Terraform](https://img.shields.io/badge/Terraform-v1.16.0-7B42BC?logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-ca--west--1%20(Calgary)-FF9900?logo=amazonaws&logoColor=white)
![Status](https://img.shields.io/badge/Status-Deployed%20%26%20Load--Tested-success)

A fully reproducible, Infrastructure-as-Code rebuild of a highly available 3-tier AWS
architecture, VPC, Auto Scaling, Application Load Balancer, Multi-AZ RDS, and a
CloudFront/S3 content delivery layer, deployed end-to-end with Terraform, then
load-tested with real traffic to trigger and confirm actual scale-out and scale-in
behavior.

This is the Infrastructure-as-Code follow-up to the console-built version of the same
architecture: same design, but provisioned, versioned, and torn down entirely through
Terraform instead of manual console clicks.

---

## Table of Contents

- [Architecture](#architecture)
- [Tech Stack](#tech-stack)
- [Build Process](#build-process)
- [Resource Verification](#resource-verification)
- [Load Testing & Auto Scaling Proof](#load-testing--auto-scaling-proof)
- [Results](#results)
- [Challenges & How They Were Solved](#challenges--how-they-were-solved)
- [Teardown](#teardown)
- [Repo Structure](#repo-structure)

---

## Architecture

```mermaid
flowchart TB
    Internet((Internet))
    ALB[Application Load Balancer<br/>public subnets, 2 AZs]
    ASG[Auto Scaling Group<br/>EC2 · min 2 / max 4<br/>private subnets]
    RDS[(RDS MySQL<br/>Multi-AZ<br/>private subnets)]
    S3[S3 Bucket<br/>static assets]
    CF[CloudFront CDN<br/>Origin Access Control]

    Internet --> ALB
    ALB --> ASG
    ASG --> RDS
    Internet --> CF
    CF --> S3
```

- **Region:** `ca-west-1` (Calgary)
- **Provisioning:** 100% Terraform — VPC, subnets, route tables, IGW, NAT Gateway,
  security groups, ALB, target group, launch template, Auto Scaling Group with a
  target-tracking scaling policy, Multi-AZ RDS, S3 bucket, and a CloudFront
  distribution with Origin Access Control
- **31 resources** created on `terraform apply`, **31 resources** cleanly removed on
  `terraform destroy` — zero manual cleanup

---

## Tech Stack

|Layer |Services / Tools |
|---|---|
| IaC | Terraform v1.16.0, AWS provider v5.100.0 |
| Compute | Amazon EC2, Auto Scaling Groups, Launch Templates |
| Networking | Amazon VPC, public/private subnets, Internet Gateway, NAT Gateway |
| Load Balancing | Application Load Balancer, Target Groups |
| Database | Amazon RDS (MySQL), Multi-AZ |
| Content Delivery | Amazon S3, Amazon CloudFront, Origin Access Control |
| Monitoring | Amazon CloudWatch (target-tracking alarms) |
| Load Testing | `hey` |

---

## Build Process

**1. Upgrade Terraform to the current version**
Started on an outdated local install (v1.14.9) and upgraded to v1.16.0 via
Chocolatey before touching the project, to avoid provider compatibility issues
down the line.

| | |
|---|---|
|https://tinyurl.com/terraform-version-outdated | Terraform flagging itself as out of date (v1.14.9), with the current version (1.16.0) noted directly in the CLI output. |
|https://tinyurl.com/terraform-upgrade-chocolatey | Upgrading via `choco upgrade terraform` — Chocolatey pulls, verifies, and installs v1.16.0 in one step. |
|https://tinyurl.com/terraform-version-updated | Confirmed on v1.16.0, with the `hashicorp/aws` provider resolved at v5.100.0. |

**2. Project structure**
Modularized into `vpc`, `security_groups`, `alb`, `asg`, `rds`, and `cdn` — each
module owns one layer of the architecture, wired together from a root `main.tf`.

https://tinyurl.com/vscode-project-structure
*The full module layout in VS Code - six modules, each with its own `main.tf`,
`variables.tf`, and `outputs.tf`.*

**3. Init → Validate → Plan → Apply**

| | |
|---|---|
|https://tinyurl.com/terraform-init-success | `terraform init` — all six modules and the `hashicorp/aws` provider initialize cleanly. |
| https://tinyurl.com/terraform-validate-success | `terraform validate` — configuration syntax confirmed valid before planning. |
| https://tinyurl.com/terraform-plan-output | `terraform plan` — 31 resources queued to add, 0 to change, 0 to destroy. |
| https://tinyurl.com/terraform-apply-confirm | `terraform apply` at the confirmation prompt, about to provision the full stack. |
| https://tinyurl.com/terraform-apply-progress | Resources creating in real time — CloudFront origin access control, VPC, S3 bucket, and NAT Gateway EIP all in flight. |

**4. Real errors hit during apply — and the fixes**

Two genuine errors came up on the first `apply`, both configuration issues rather
than code bugs:

- **S3 bucket name collision with AWS's Account Regional Namespace feature** — the
  bucket name matched the reserved `-{accountId}-{region}-an` suffix pattern, which
  AWS auto-detects and requires an extra request header for. Fixed by renaming the
  bucket to `portfolio-app-assets-3tier`.
- **Availability Zones didn't exist in the target region** — `terraform.tfvars`
  was missing explicit `ca-west-1` AZs, so subnets defaulted to placeholder values
  that don't exist there. Fixed by adding `aws_region = "ca-west-1"` and
  `azs = ["ca-west-1a", "ca-west-1b"]`.

https://tinyurl.com/terraform-apply-error
*Both errors as they actually appeared — `MissingNamespaceHeader` on the S3
bucket and `InvalidParameterValue` on the subnet Availability Zones.*

**5. Clean apply and outputs**

https://tinyurl.com/terraform-apply-complete
*`Apply complete! Resources: 33 added, 0 changed, 0 destroyed.` with all four
outputs populated: ALB DNS name, CloudFront domain, RDS endpoint, and VPC ID.*

**6. Confirming the load balancer actually balances**

Hitting the ALB's DNS name twice in a row returns responses from two different
private IPs — direct proof traffic is being distributed, not pinned to one
instance.

| | |
|---|---|
| https://tinyurl.com/alb-response-instance-1 | Response from the first instance (`10-0-11-38`). |
| https://tinyurl.com/alb-response-instance-2 | Same URL, second request — response from a different instance (`10-0-12-48`). |

https://tinyurl.com/terraform-apply-full-resource
*The complete apply log — every resource Terraform provisioned, in order,
across all six modules.*

---

## Resource Verification

Spot-checking the AWS Console to confirm Terraform built exactly what it claimed to.

| Resource | Screenshot |
|---|---|
| VPC | https://tinyurl.com/vpc-terraform |
| Subnets (2 public, 2 private) | https://tinyurl.com/subnets-creation |
| Route tables | https://tinyurl.com/route-tables |
| Public route table → Internet Gateway | https://tinyurl.com/route-table-public-routes |
| Public subnet associations | https://tinyurl.com/public-subnet-associations |
| Private route table → NAT Gateway | https://tinyurl.com/route-table-private-route |
| Private subnet associations | https://tinyurl.com/private-subnet-associations |
| Internet Gateway, attached | https://tinyurl.com/internet-gateway |
| NAT Gateway, available | https://tinyurl.com/nat-gateway |
| Initial 2 EC2 instances, running | https://tinyurl.com/ec2-instances-running |
| Elastic IP reserved for the NAT Gateway | https://tinyurl.com/elastic-ip-for-nat |
| Application Load Balancer, active | https://tinyurl.com/load-balancer-created |
| Target group, linked to the ALB | https://tinyurl.com/target-group-created |
| Auto Scaling Group, at desired capacity | https://tinyurl.com/auto-scaling-group |
| Target-tracking dynamic scaling policy | https://tinyurl.com/dynamic-scaling-policy |
| Both instances attached to the ASG, healthy | https://tinyurl.com/asg-instances-attached |
| CloudFront distribution, enabled | https://tinyurl.com/CDN-created |

**CDN verification** — CloudFront domain `d2uosezalkh73t.cloudfront.net` serving
static assets directly from the (fully private) S3 origin:

| | |
|---|---|
| https://tinyurl.com/static-asset-beach | `beach.jpg` served through CloudFront. |
| https://tinyurl.com/static-asset-coffee | `coffee.jpg` served through CloudFront — confirms the first result wasn't a one-off. |
| https://tinyurl.com/cloudfront-full-html-page | A full HTML page with an embedded image, served entirely from the CDN. |
| https://tinyurl.com/alb-curl-test-200 | `curl` against the ALB's DNS name returning `200 OK` with the expected response body. |

---

## Load Testing & Auto Scaling Proof

The part that actually proves the architecture, not just that it deployed.

**1. Install the load testing tool on the EC2 instance**

https://tinyurl.com/installing-hey-load-test-too
*Installing `hey` via `go install` directly on the instance, so the load test
runs from inside the same network as the ALB — no internet round-trip skewing
the results.*

**2. Run the load test**

https://tinyurl.com/hey-load-test-results
*`hey -z 5m -c 50` against the ALB — 5 minutes of sustained load at 50
concurrent connections, completing at **10,714 requests/sec** with a 0.0151s
average response time.*

**3. CPU spikes, alarm triggers**

https://tinyurl.com/cloudwatch-cpu-spike
*CloudWatch shows CPUUtilization climbing to 66.9%, crossing the
target-tracking alarm's threshold — this is what actually triggers a scale-out
action, not just the load test running.*

**4. Scale-out: 2 → 3 instances**

| | |
|---|---|
| https://tinyurl.com/asg-scale-out-triggered | ASG Activity History: alarm triggers, desired capacity moves from 2 to 3, new instance launches and begins warm-up. |
| https://tinyurl.com/asg-third-instance-created | Third instance launch completes successfully — group back to "at desired capacity" with 3/3 healthy. |
| https://tinyurl.com/asg-instance-management | Instance management view confirming all 3 instances `InService` and `Healthy`. |
| https://tinyurl.com/ec2-instances-scaled-to-3 | EC2 console independently confirms 3 running instances. |

**5. Load subsides, CPU drops, alarm reverses**

https://tinyurl.com/cloudwatch-cpu-dropped
*CPUUtilization back down to 6.6% once the load test finishes — this is what
triggers the scale-in policy to kick in.*

**6. Scale-in: 3 → 2 instances, with proper connection draining**

| | |
|---|---|
| https://tinyurl.com/asg-scale-in-triggered-3-to-2 | ASG Activity History: scale-in triggered, one instance selected for termination and marked "Connection draining in progress — Waiting For ELB Connection Draining." |
| https://tinyurl.com/asg-instance-terminating | Instance management view mid-drain — one instance `Terminating` while the other two remain `Healthy`. |
| https://tinyurl.com/asg-back-to-baseline | Termination completes successfully — group back to 2/2 healthy, its original baseline. |

This confirms the scale-in wasn't just "kill an instance" — it waited for
in-flight connections to finish draining first, meaning zero dropped requests
during the scale-down.

---

## Results

- ✅ 31 AWS resources provisioned entirely through Terraform, with zero manual
  console configuration
- ✅ Load balancer confirmed distributing traffic across multiple targets, not
  pinned to one instance
- ✅ Real load test sustained **10,714 req/sec** and pushed CPU to 66.9%,
  triggering genuine (not simulated) Auto Scaling behavior
- ✅ Scale-out completed cleanly: 2 → 3 instances, fully automatic
- ✅ Scale-in completed cleanly: 3 → 2 instances, with ELB connection draining
  completing before termination — zero dropped in-flight requests
- ✅ Full teardown via `terraform destroy` — 31 resources removed, zero manual
  cleanup

---

## Challenges & How They Were Solved

**S3 bucket name accidentally matched a reserved AWS naming pattern**
AWS's S3 Account Regional Namespace feature auto-detects bucket names ending in
`-{accountId}-{region}-an` and requires an additional request header Terraform
wasn't sending, causing `MissingNamespaceHeader`. Fixed by renaming the bucket
to avoid the pattern entirely.

**Availability Zones didn't match the deployment region**
`terraform.tfvars` still referenced placeholder AZs that don't exist in
`ca-west-1`. Fixed by explicitly setting `aws_region` and `azs` for the actual
target region.

**Making sure the load test actually reached the target**
Running `hey` from inside the VPC (rather than from a local machine over the
internet) was the key decision that let a real load test hit high enough
throughput to move CPU utilization meaningfully — confirmed by the 10,714 req/sec
result actually crossing the scaling threshold.

---

## Teardown

```bash
terraform destroy
```

https://tinyurl.com/terraform-destroy
*`Destroy complete! Resources: 31 destroyed.` — every resource removed in
correct dependency order, no orphaned infrastructure left behind.*

---

## Repo Structure

```
terraform-3tier/
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── terraform.tfvars.example      # copy to terraform.tfvars and fill in your values
├── modules/
│   ├── vpc/
│   ├── security_groups/
│   ├── alb/
│   ├── asg/
│   ├── rds/
│   └── cdn/
└── screenshots/                   # all 47 screenshots referenced above
```

---

**Author:** Temidayo Akinboni · AWS Cloud Solutions Architect · DevOps Engineer

