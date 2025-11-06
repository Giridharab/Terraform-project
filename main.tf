provider "aws" {
  region = var.aws_region
  
  # AWS credentials will be read from environment variables:
  # AWS_ACCESS_KEY_ID
  # AWS_SECRET_ACCESS_KEY
}

module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr             = var.vpc_cidr
  environment          = var.environment
  availability_zones   = var.availability_zones
  private_subnets     = var.private_subnets
  public_subnets      = var.public_subnets
  enable_nat_gateway  = var.enable_nat_gateway
  tags                = var.tags
}

# --- EC2 instance: ubuntu machine ---

# Find latest Ubuntu 22.04/20.04 AMI (depends on region)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*", "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# Create an EC2 key pair from provided public key
resource "aws_key_pair" "deployer" {
  count      = var.ssh_public_key != "" ? 1 : 0
  key_name   = "deployer-key-${var.environment}"
  public_key = var.ssh_public_key
}

# Security group allowing SSH (adjust CIDR as needed)
resource "aws_security_group" "ssh" {
  name        = "${var.environment}-allow-ssh"
  description = "Allow SSH inbound"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({ Name = "${var.environment}-sg-ssh" }, var.tags)
}

# EC2 instance
resource "aws_instance" "ubuntu" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.public_subnet_ids[0]
  key_name               = var.ssh_public_key != "" ? aws_key_pair.deployer[0].key_name : null
  vpc_security_group_ids = [aws_security_group.ssh.id]

  tags = merge({ Name = "ubuntu machine" }, var.tags)
}