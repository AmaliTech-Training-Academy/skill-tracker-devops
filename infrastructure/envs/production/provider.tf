terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  backend "s3" {
    bucket         = "sdt-terraform-state"
    key            = "envs/production/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "sdt-production-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Skills Development Tracker (SDT)"
      Environment = "production"
      ManagedBy   = "Terraform"
    }
  }
}
