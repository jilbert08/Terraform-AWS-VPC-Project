variable "aws_region" {
  description = "AWS region to create the resources in"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Project name, used in resource names and tags"
  type        = string
  default     = "terraform-vpc"
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be dev, test or prod."
  }
}

variable "vpc_cidr" {
  description = "IP range (CIDR block) of the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid CIDR block, for example 10.0.0.0/16."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets (one per Availability Zone)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets (one per Availability Zone)"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "ssh_allowed_cidr" {
  description = "IP range allowed to connect with SSH (port 22). Use your own public IP with /32"
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.ssh_allowed_cidr, 0))
    error_message = "ssh_allowed_cidr must be a valid CIDR block, for example 203.0.113.10/32."
  }
}
