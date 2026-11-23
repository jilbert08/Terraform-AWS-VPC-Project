# Terraform: Basic AWS Network Infrastructure (VPC, Subnets, Routing, Security Group)

## Project Objective
Use **Terraform** (Infrastructure as Code) to create a complete basic AWS network in the **Mumbai region (ap-south-1)**:
a custom VPC, public and private subnets in two Availability Zones, an Internet Gateway, route tables and a security group.
All values (region, CIDR ranges, names) are configurable through variables.

## AWS Architecture

```
                               Internet
                                  │
                        ┌─────────┴─────────┐
                        │ Internet Gateway  │
                        └─────────┬─────────┘
 VPC 10.0.0.0/16 (ap-south-1)     │
 ┌────────────────────────────────┼─────────────────────────────────┐
 │                  Public route table: 0.0.0.0/0 → IGW             │
 │   ┌────────────── ap-south-1a ─────┐  ┌──── ap-south-1b ────────┐ │
 │   │ Public subnet 10.0.1.0/24      │  │ Public subnet 10.0.2.0/24│ │
 │   │  (auto-assign public IP)       │  │  (auto-assign public IP) │ │
 │   ├────────────────────────────────┤  ├──────────────────────────┤ │
 │   │ Private subnet 10.0.11.0/24    │  │ Private subnet 10.0.12.0/24│
 │   │  (no internet route)           │  │  (no internet route)     │ │
 │   └────────────────────────────────┘  └──────────────────────────┘ │
 │                  Private route table: local only                  │
 │   Security group "web-sg": inbound 80, 443 (all), 22 (allowed IP) │
 └──────────────────────────────────────────────────────────────────┘
```

| Resource | Terraform name | Purpose |
|---|---|---|
| VPC | `aws_vpc.main` | Private network `10.0.0.0/16` with DNS support |
| Internet Gateway | `aws_internet_gateway.main` | Connects the VPC to the internet |
| Public subnets (2) | `aws_subnet.public[0..1]` | `10.0.1.0/24`, `10.0.2.0/24`; instances get public IPs |
| Private subnets (2) | `aws_subnet.private[0..1]` | `10.0.11.0/24`, `10.0.12.0/24`; no direct internet access |
| Public route table | `aws_route_table.public` | Route `0.0.0.0/0 → Internet Gateway` |
| Private route table | `aws_route_table.private` | Only the local VPC route |
| Route table associations (4) | `aws_route_table_association.*` | Link each subnet to its route table |
| Security group | `aws_security_group.web` | Inbound HTTP 80, HTTPS 443 from anywhere, SSH 22 from `ssh_allowed_cidr`; all outbound |

**Total: 13 resources.** All of them are **free** in AWS (no NAT Gateway, no EC2 instances).

## Repository Structure
```
├── README.md
├── .gitignore                 # excludes state files, .terraform/ and credentials
├── terraform/
│   ├── main.tf                # provider + all networking resources
│   ├── variables.tf           # input variables with defaults and validation
│   ├── outputs.tf             # IDs printed after deployment
│   ├── terraform.tfvars       # values used for this deployment
│   └── .terraform.lock.hcl    # provider version lock (created by terraform init)
├── logs/
│   ├── terraform-init.log
│   ├── terraform-validate.log
│   ├── terraform-plan.log
│   ├── terraform-apply.log
│   ├── terraform-output.log
│   ├── aws-verify.log
│   └── terraform-destroy.log
└── docs/screenshots/          # AWS Console evidence
```

## Variables

| Variable | Type | Default | Description |
|---|---|---|---|
| `aws_region` | string | `ap-south-1` | AWS region |
| `project_name` | string | `terraform-vpc` | Used in names and tags |
| `environment` | string | `dev` | `dev`, `test` or `prod` (validated) |
| `vpc_cidr` | string | `10.0.0.0/16` | VPC IP range (validated) |
| `public_subnet_cidrs` | list(string) | `["10.0.1.0/24", "10.0.2.0/24"]` | One public subnet per entry |
| `private_subnet_cidrs` | list(string) | `["10.0.11.0/24", "10.0.12.0/24"]` | One private subnet per entry |
| `ssh_allowed_cidr` | string | `0.0.0.0/0` | Who may use SSH; set your own IP `/32` for real use |

Change values in `terraform/terraform.tfvars`, or on the command line: `terraform plan -var="environment=test"`.

## Outputs
`vpc_id`, `vpc_cidr`, `availability_zones`, `public_subnet_ids`, `private_subnet_ids`, `internet_gateway_id`, `public_route_table_id`, `private_route_table_id`, `web_security_group_id`.

## Setup Requirements
| Requirement | Install / check |
|---|---|
| Terraform ≥ 1.5 | `winget install Hashicorp.Terraform` → `terraform -version` |
| AWS CLI v2 | `winget install Amazon.AWSCLI` → `aws --version` |
| AWS IAM user with access keys | Permission `AmazonEC2FullAccess` (VPC resources are EC2 APIs) |
| AWS credentials configured | `aws configure` → `aws sts get-caller-identity` |

Credentials are stored by the AWS CLI in `%USERPROFILE%\.aws\` – **never** in this repository.

## CLI Commands
Run inside the `terraform` folder:

```powershell
terraform init                 # download the AWS provider
terraform fmt                  # format the code
terraform validate             # check the syntax
terraform plan -out=tfplan     # preview: 13 to add
terraform apply tfplan         # create the resources
terraform output               # show the IDs
terraform state list           # list managed resources
terraform destroy              # delete everything
```

Verify with the AWS CLI:
```powershell
aws ec2 describe-vpcs --filters "Name=tag:Project,Values=terraform-vpc" --output table
aws ec2 describe-subnets --filters "Name=tag:Project,Values=terraform-vpc" --query "Subnets[].[Tags[?Key=='Name']|[0].Value,CidrBlock,AvailabilityZone,MapPublicIpOnLaunch]" --output table
aws ec2 describe-security-groups --filters "Name=tag:Project,Values=terraform-vpc" --output table
```

## Execution Logs
| Log | Shows |
|---|---|
| [`logs/terraform-init.log`](logs/terraform-init.log) | Provider download, *Terraform has been successfully initialized!* |
| [`logs/terraform-validate.log`](logs/terraform-validate.log) | *Success! The configuration is valid.* |
| [`logs/terraform-plan.log`](logs/terraform-plan.log) | *Plan: 13 to add, 0 to change, 0 to destroy.* |
| [`logs/terraform-apply.log`](logs/terraform-apply.log) | *Apply complete! Resources: 13 added* and the outputs |
| [`logs/terraform-output.log`](logs/terraform-output.log) | All output values |
| [`logs/aws-verify.log`](logs/aws-verify.log) | AWS CLI view of the created VPC, subnets and security group |
| [`logs/terraform-destroy.log`](logs/terraform-destroy.log) | *Destroy complete! Resources: 13 destroyed.* |

## Screenshots
| # | Evidence | Image |
|---|---|---|
| 1 | VPC in the AWS Console | ![](docs/screenshots/01-vpc.png) |
| 2 | Subnets (2 public, 2 private) | ![](docs/screenshots/02-subnets.png) |
| 3 | Route tables | ![](docs/screenshots/03-route-tables.png) |
| 4 | Security group inbound rules | ![](docs/screenshots/04-security-group.png) |
| 5 | VPC resource map | ![](docs/screenshots/05-resource-map.png) |

## Security Notes
- State files (`*.tfstate`) and `.terraform/` are excluded by `.gitignore`; state can contain sensitive data.
- No access keys are stored in the code; the AWS provider reads them from the AWS CLI profile.
- For real environments set `ssh_allowed_cidr` to your own IP (`x.x.x.x/32`) and use a remote state backend (S3 + DynamoDB lock).

## Author
**Jilbert Ekka** – RHCSA Certified | Linux & DevOps
