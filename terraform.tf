terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  # S3 backend for remote state management
  # Configuration is provided via -backend-config flags or backend.hcl
  backend "s3" {
    key     = "specter-lab/terraform.tfstate"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "Specter-AWS-Lab"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}
