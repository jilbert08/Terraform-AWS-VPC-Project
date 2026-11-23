# Values used for this deployment (they override the defaults in variables.tf)
aws_region           = "ap-south-1"
project_name         = "terraform-vpc"
environment          = "dev"
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24"]
ssh_allowed_cidr     = "0.0.0.0/0"
