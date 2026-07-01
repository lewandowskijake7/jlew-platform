# VPC Module Learning Plan

You already have the right skeleton in [`terraform/modules/vpc/main.tf`](terraform/modules/vpc/main.tf) and subnet-CIDR notes in [`terraform/modules/vpc/README-vpc.md`](terraform/modules/vpc/README-vpc.md). This plan turns that into a complete module by answering: **which Terraform resource maps to which concept**, and **which variables wire it together**.

Target layout (matches your README, region `us-east-2`):

| Subnet | AZ | CIDR |
|--------|-----|------|
| public-1 | us-east-2a | `10.0.0.0/24` |
| public-2 | us-east-2b | `10.0.1.0/24` |
| private-1 | us-east-2a | `10.0.10.0/24` |
| private-2 | us-east-2b | `10.0.11.0/24` |

VPC CIDR: `10.0.0.0/16`

---

## Architecture (what you're building)

```
                         +-----------+
                         | Internet  |
                         +-----+-----+
                               |
                               v
                    +---------------------+
                    | aws_internet_gateway|
                    +----------+----------+
                               |
                               v
                    +---------------------+
                    |  public route table |  (shared across AZs)
                    +----+-------------+--+
                         |             |
           +-------------+--+       +--+-------------+
           | public subnet 2a |   | public subnet 2b |
           |                  |   |                  |
           | aws_nat_gateway 2a|   | aws_nat_gateway 2b|
           +--------+---------+   +---------+--------+
                ^    |                       ^    |
                |    |                       |    |
           aws_eip 2a |                  aws_eip 2b |
                    |                       |
                    v                       v
           +--------+---------+   +---------+--------+
           | private RT 2a    |   | private RT 2b    |
           +--------+---------+   +---------+--------+
                    |                       |
                    v                       v
           +--------+---------+   +---------+--------+
           | private subnet 2a|   | private subnet 2b|
           +------------------+   +------------------+

All of the above lives inside aws_vpc.
```

**Traffic rules (concepts you already know, now with resource names):**
- Public subnet → `aws_route` on public RT: `0.0.0.0/0` → `aws_internet_gateway`
- Private subnet → `aws_route` on private RT: `0.0.0.0/0` → `aws_nat_gateway` (in the **public** subnet of the same AZ)
- NAT sits in public subnet; needs `aws_eip` with `domain = "vpc"`

---

## Suggested file layout

Keep the standard module files you already have; split resources by concern so you can learn one layer at a time:

| File | Purpose |
|------|---------|
| [`variables.tf`](terraform/modules/vpc/variables.tf) | All inputs |
| [`locals.tf`](terraform/modules/vpc/locals.tf) | Naming, tag merging, derived values |
| [`vpc.tf`](terraform/modules/vpc/vpc.tf) | VPC + IGW |
| [`subnets.tf`](terraform/modules/vpc/subnets.tf) | Public and private subnets |
| [`nat.tf`](terraform/modules/vpc/nat.tf) | EIPs + NAT gateways |
| [`routes.tf`](terraform/modules/vpc/routes.tf) | Route tables, routes, associations |
| [`outputs.tf`](terraform/modules/vpc/outputs.tf) | IDs/cidrs for downstream modules |
| [`versions.tf`](terraform/modules/vpc/versions.tf) | Provider constraints (mirror bootstrap: `aws ~> 6.51`) |
| [`main.tf`](terraform/modules/vpc/main.tf) | Delete or leave empty after split |

Move your existing 3 resources into `vpc.tf` / `subnets.tf` as the starting point.

---

## Phase 1 — Foundation (VPC + subnets)

### Resources to define

| Concept | Terraform resource | Key arguments to look up |
|---------|-------------------|--------------------------|
| VPC | `aws_vpc` | `cidr_block`, `enable_dns_hostnames`, `enable_dns_support`, `tags` |
| Public subnet | `aws_subnet` | `vpc_id`, `cidr_block`, `availability_zone`, `map_public_ip_on_launch = true`, `tags` |
| Private subnet | `aws_subnet` | same, but `map_public_ip_on_launch = false` |

**Learning exercise:** Replace your single `aws_subnet.public` / `aws_subnet.private` with **`for_each`** or **`count`** over a list of subnet definitions. `for_each` on a map keyed by name (e.g. `"public-2a"`) is easier to read than raw indexes.

**Optional data source** (if you don't pass AZs explicitly):

```hcl
data "aws_availability_zones" "available" {
  state = "available"
}
```

Use `slice(data.aws_availability_zones.available.names, 0, var.az_count)` only if you want the module to discover AZs — passing AZs explicitly is simpler for learning.

### Variables (Phase 1)

| Variable | Type | Purpose | Example default |
|----------|------|---------|-----------------|
| `name` | `string` | Prefix for resource names/tags | `"jlew-dev"` |
| `vpc_cidr` | `string` | VPC CIDR block | `"10.0.0.0/16"` |
| `azs` | `list(string)` | AZs to spread subnets across | `["us-east-2a", "us-east-2b"]` |
| `public_subnet_cidrs` | `list(string)` | One CIDR per public subnet; length must match `azs` | `["10.0.0.0/24", "10.0.1.0/24"]` |
| `private_subnet_cidrs` | `list(string)` | One CIDR per private subnet | `["10.0.10.0/24", "10.0.11.0/24"]` |
| `tags` | `map(string)` | Common tags merged onto every resource | `{ Project = "jlew-platform" }` |

**Validation to write yourself** (good learning step in `variables.tf`):

```hcl
validation {
  condition     = length(var.public_subnet_cidrs) == length(var.azs)
  error_message = "public_subnet_cidrs must have one entry per AZ."
}
```

Same for `private_subnet_cidrs`.

### Outputs (Phase 1)

| Output | Value |
|--------|-------|
| `vpc_id` | `aws_vpc.main.id` |
| `vpc_cidr_block` | `aws_vpc.main.cidr_block` |
| `public_subnet_ids` | list/map of public subnet IDs |
| `private_subnet_ids` | list/map of private subnet IDs |

**Checkpoint:** `terraform plan` in a throwaway root module should show 1 VPC + 4 subnets, no routes yet.

---

## Phase 2 — Internet connectivity

### Resources to define

| Concept | Terraform resource | Key arguments |
|---------|-------------------|---------------|
| Internet gateway | `aws_internet_gateway` | `vpc_id`, `tags` |
| Elastic IP (for NAT) | `aws_eip` | `domain = "vpc"`, `tags`; use `depends_on = [aws_internet_gateway.main]` |
| NAT gateway | `aws_nat_gateway` | `allocation_id` (EIP), `subnet_id` (must be **public** subnet in same AZ), `tags` |

**NAT count decision (you chose full NAT):** Start with **one NAT per AZ** (HA, matches diagram). Add a later variable `single_nat_gateway` if you want a cheaper dev mode — not required for v1.

**Dependency gotcha to discover:** NAT gateways must be created in a public subnet that already has a route to the IGW. Build IGW + public route table (Phase 3) before or alongside NAT, or Terraform may fail at apply time.

### Variables (Phase 2)

No new required variables if NAT is always on. Optional:

| Variable | Type | Default | Purpose |
|----------|------|---------|---------|
| `enable_nat_gateway` | `bool` | `true` | Toggle NAT (you chose full; still useful for cost experiments) |
| `single_nat_gateway` | `bool` | `false` | If `true`, one NAT shared by all private subnets |

### Outputs (Phase 2)

| Output | Value |
|--------|-------|
| `internet_gateway_id` | IGW id |
| `nat_gateway_ids` | list of NAT ids |

---

## Phase 3 — Routing (where concepts click together)

### Resources to define

| Concept | Terraform resource | Key arguments |
|---------|-------------------|---------------|
| Public route table | `aws_route_table` | `vpc_id`, `tags` |
| Default public route | `aws_route` | `route_table_id`, `destination_cidr_block = "0.0.0.0/0"`, `gateway_id` = IGW |
| Associate public subnets | `aws_route_table_association` | `subnet_id`, `route_table_id` |
| Private route table (per AZ) | `aws_route_table` | one per AZ when using per-AZ NAT |
| Default private route | `aws_route` | `destination_cidr_block = "0.0.0.0/0"`, `nat_gateway_id` |
| Associate private subnets | `aws_route_table_association` | pair each private subnet with its AZ's private RT |

**Design choice for you to implement:**
- **Shared public RT** — one `aws_route_table` for all public subnets (common, simpler)
- **Per-AZ private RT** — each private subnet routes to the NAT in its AZ (recommended with per-AZ NAT)

### Outputs (Phase 3)

| Output | Value |
|--------|-------|
| `public_route_table_id` | public RT id |
| `private_route_table_ids` | list/map of private RT ids |

**Checkpoint:** After apply, a resource in a public subnet can reach the internet; a resource in a private subnet can reach the internet **outbound** via NAT (inbound from internet still blocked unless you add load balancers/security groups later).

---

## Phase 4 — Module polish (still learning-friendly)

### `locals.tf` patterns to implement

- `local.name_prefix = var.name`
- `local.common_tags = merge(var.tags, { Name = "...", ManagedBy = "terraform" })`
- Subnet name map: `"${var.name}-public-${var.azs[i]}"`

### `versions.tf`

Match [`terraform/bootstrap/main.tf`](terraform/bootstrap/main.tf):

```hcl
terraform {
  required_version = ">= 1.15.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.51"
    }
  }
}
```

Modules typically **do not** include a `provider` block — the caller provides region.

### Indentation

Bootstrap uses 2 spaces; your module uses 4. Pick one (2 spaces matches the rest of the repo).

---

## Complete resource checklist

When done, your module should contain **~15–20 resources** (with 2 AZs, per-AZ NAT):

| # | Resource | Count (2 AZ) |
|---|----------|--------------|
| 1 | `aws_vpc` | 1 |
| 2 | `aws_internet_gateway` | 1 |
| 3 | `aws_subnet` (public) | 2 |
| 4 | `aws_subnet` (private) | 2 |
| 5 | `aws_eip` | 2 |
| 6 | `aws_nat_gateway` | 2 |
| 7 | `aws_route_table` (public) | 1 |
| 8 | `aws_route_table` (private) | 2 |
| 9 | `aws_route` (to IGW) | 1 |
| 10 | `aws_route` (to NAT) | 2 |
| 11 | `aws_route_table_association` (public) | 2 |
| 12 | `aws_route_table_association` (private) | 2 |

**Optional later** (not needed for v1): `aws_flow_log`, `aws_vpc_endpoint` (S3 gateway endpoint saves NAT data charges), managing `aws_default_security_group`, `aws_network_acl`.

---

## Variables summary (full contract)

**Required / core:**

- `name` — string
- `vpc_cidr` — string
- `azs` — list(string)
- `public_subnet_cidrs` — list(string)
- `private_subnet_cidrs` — list(string)

**Optional / operational:**

- `tags` — map(string), default `{}`
- `enable_dns_hostnames` — bool, default `true` (needed for many AWS services)
- `enable_dns_support` — bool, default `true`
- `enable_nat_gateway` — bool, default `true`
- `single_nat_gateway` — bool, default `false`

**Do not add** `region` as a module variable — set it on the provider in the root module.

---

## Outputs summary (what future stacks will consume)

Downstream modules (ECS, RDS, ALB, etc.) typically need:

| Output | Why callers need it |
|--------|---------------------|
| `vpc_id` | Security groups, RDS, ECS service |
| `public_subnet_ids` | ALB, NAT placement |
| `private_subnet_ids` | ECS tasks, RDS, Lambda in VPC |
| `vpc_cidr_block` | Security group rules |
| `nat_gateway_ids` | Debugging, monitoring |
| `internet_gateway_id` | Rarely needed; nice for docs |

Prefer **maps keyed by AZ or subnet name** over bare lists when outputs will be referenced by humans.

---

## How you'll test it (after module is built)

Create a minimal root at e.g. `terraform/environments/dev/main.tf` (not in scope to build now, but this is how you validate):

```hcl
module "vpc" {
  source = "../../modules/vpc"

  name                   = "jlew-dev"
  vpc_cidr               = "10.0.0.0/16"
  azs                    = ["us-east-2a", "us-east-2b"]
  public_subnet_cidrs    = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidrs   = ["10.0.10.0/24", "10.0.11.0/24"]
}
```

Run `terraform init`, `terraform plan`, then `apply` when ready. **NAT + EIP will incur cost** (~$64/mo for 2 NAT gateways in us-east-2).

Backend key suggestion when you add environments: `environments/dev/vpc/terraform.tfstate` in your existing `jlew-platform-state` bucket.

---

## Recommended learning order

1. **Variables + locals** — define the contract before more resources
2. **Refactor subnets** to `for_each` — hardest Terraform syntax; do it early
3. **IGW + public routing** — verify public internet path
4. **EIP + NAT + private routing** — verify outbound from private
5. **Outputs** — expose IDs for your future self
6. **`terraform validate` + `plan`** after each phase

**Docs to read per resource** (AWS provider registry): search `terraform aws_vpc`, `aws_subnet`, `aws_internet_gateway`, `aws_nat_gateway`, `aws_route_table`, `aws_route`, `aws_route_table_association`, `aws_eip`.

---

## Alignment with your current code

Your [`main.tf`](terraform/modules/vpc/main.tf) hardcodes `10.0.1.0/24` public and `10.0.2.0/24` private — the README's multi-AZ scheme uses `10.0.0.0/24`, `10.0.1.0/24` public and `10.0.10.0/24`, `10.0.11.0/24` private. Adopt the README layout when you parameterize; it leaves room between public (`10.0.0–1`) and private (`10.0.10–11`) CIDR blocks for future subnets (e.g. DB tier `10.0.20.0/24`).
