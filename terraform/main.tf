terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# --- 1. VPC & Networking ---
resource "aws_vpc" "assessment_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "devops-assessment-vpc"
    Environment = "production"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.assessment_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "devops-assessment-public-subnet"
  }
}

# --- 2. EC2 Instance for Kubernetes / App Deployment ---
resource "aws_instance" "app_server" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "devops-assessment-server"
  }
}
