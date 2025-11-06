# Environment specific values
aws_region = "us-east-1"
environment = "dev"
vpc_cidr = "10.0.0.0/16"

# Availability zones and subnet configuration
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
private_subnets    = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnets     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

# Feature flags
enable_nat_gateway = true

# Resource tagging
tags = {
  Terraform   = "true"
  Environment = "dev"
  Project     = "MyProject"
}