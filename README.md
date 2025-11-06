# Terraform-Project

This repository contains Terraform configuration to provision a VPC and an Ubuntu EC2 instance on AWS. It is organized to be modular and easy to customize for different environments.

## What this repo provisions

- A VPC with DNS support enabled
- 3 public subnets and 3 private subnets across 3 AZs
- Internet Gateway for public subnets
- NAT Gateways for outbound access from private subnets
- Route tables and associations for public/private subnets
- Elastic IPs used by NAT Gateways
- A security group allowing SSH access
- An Ubuntu EC2 instance (t3.micro) placed in the first public subnet

## Repository layout

- `main.tf` — root module, provider config and resources (calls `modules/vpc` and contains EC2 resources)
- `variables.tf` — root-level variables and defaults
- `terraform.tfvars` — recommended variable values (environment-specific)
- `versions.tf` — Terraform and provider constraints
- `modules/vpc/` — reusable VPC module
  - `modules/vpc/main.tf` — VPC, subnets, IGW, NATs, route tables
  - `modules/vpc/variables.tf` — module variables
  - `modules/vpc/outputs.tf` — module outputs
- `iam/terraform-ec2-policy.json` — example IAM policy to grant Terraform necessary EC2/VPC permissions
- `.env` — local environment file (NOT committed; contains AWS creds in local setup)

## Important variables

Root variables (see `variables.tf` and `terraform.tfvars`):
- `aws_region` — AWS region to deploy to (e.g. `us-east-1`)
- `vpc_cidr` — CIDR for the VPC (default `10.0.0.0/16`)
- `availability_zones` — list of AZs to create subnets in
- `public_subnets`, `private_subnets` — lists of CIDR blocks for subnets
- `enable_nat_gateway` — boolean to enable NAT gateways (default true)
- `tags` — map of tags applied to resources
- `ssh_public_key` — SSH public key data (string). If empty, Terraform will not create an AWS key pair and EC2 will be created without a key name.

Module variables for `modules/vpc` are specified in `modules/vpc/variables.tf` and include VPC CIDR, lists of subnet CIDRs, AZs, and tags.

## How to configure credentials (recommended)

1. Create a local `.env` file (this repo has an example `.env`). Do NOT commit it. Add to `.gitignore` if needed.

```
AWS_ACCESS_KEY_ID=AKIA...YOURKEY
AWS_SECRET_ACCESS_KEY=...YOURSECRET...
AWS_DEFAULT_REGION=us-east-1
```

2. Load the variables in your shell before running Terraform (zsh / bash):

```bash
set -a; source .env; set +a
```

3. Alternately, use `gh auth login` (GitHub CLI) or `aws configure` for AWS credential setup.

## How to set the SSH public key

Provide your SSH public key so Terraform can create an EC2 key pair and assign it to the instance. Do NOT put private keys in repo.

- Option A (env):

```bash
export TF_VAR_ssh_public_key="ssh-rsa AAAA... user@host"
```

- Option B (`terraform.tfvars`):

```hcl
ssh_public_key = "ssh-rsa AAAA... user@host"
```

If `ssh_public_key` is empty, the key pair resource will be skipped and EC2 will be created without key access.

## Initialize, plan and apply

1. Initialize providers and modules:

```bash
terraform init
```

2. Create a plan (safe to inspect changes):

```bash
terraform plan -out=tfplan
```

3. Apply the saved plan:

```bash
terraform apply tfplan
```

Notes about regions and state

- Terraform tracks resources in the local `terraform.tfstate` file (or remote backend if configured). Changing `aws_region` while using the same state will cause Terraform to plan replacement (destroy in old region and create in the new region).
- If you want to deploy to another region without destroying existing resources, create a new Terraform workspace or use a separate state/backend.

Example: create separate workspace for `us-east-1`:

```bash
terraform workspace new useast
set -a; source .env; set +a
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

## IAM permissions

Terraform needs permissions to read/create EC2, VPC, EIP, and related resources. An example minimal policy is in `iam/terraform-ec2-policy.json`. Apply it to the IAM user or role Terraform uses (or attach broader managed policies like `AmazonEC2FullAccess` and `AmazonVPCFullAccess` if acceptable).

## Git and GitHub

Do NOT commit secrets like `.env` or personal tokens. Use `.gitignore` (this repo already includes `.env`).

Recommended: push using GitHub CLI:

```bash
gh auth login
gh repo create REPO_NAME --public --source=. --remote=origin --push
```

Or standard flow:

```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/REPO_NAME.git
git push -u origin main
```

If you accidentally exposed a token (do NOT commit it), rotate/revoke it immediately in GitHub settings.

## Troubleshooting

- `InvalidClientTokenId` / `Invalid credentials` — check your `.env` creds or `aws configure` profile and `TF_VAR_*` env variables.
- `UnauthorizedOperation` — missing IAM permissions; attach the example policy in `iam/terraform-ec2-policy.json` or request admin to add required permissions.
- `InvalidVpcID.NotFound` — occurs when state references resources in a different region; either switch back to the original region or remove state and recreate resources in the desired region.

## Outputs

Some outputs are declared inside `modules/vpc/outputs.tf` (VPC ID, subnet IDs, NAT gateway IDs). You can add root-level outputs if you prefer to expose them at the root module.

## Next steps / improvements

- Add remote backend (S3 + DynamoDB) for safe team usage and locking.
- Add more granular IAM policy (least privilege) tuned to your account ARNs.
- Add automated tests (e.g. Terratest) or validation scripts.
- Add user-data to provision SSH keys/users and basic hardening for the Ubuntu instance.

---

If you want, I can also:
- Add a `terraform.tfvars.example` (without secrets) for easier onboarding, or
- Create a small script `scripts/push-to-github.sh` that uses `gh` to create the repo and push (you run it locally after logging in).

Tell me which extra item you'd like and I will add it.
