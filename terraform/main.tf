terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Use the AWS credential chain (for example, AWS_PROFILE or temporary credentials).
# Do not put access keys in this configuration.
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(var.tags, {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    })
  }
}

locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

module "frontend" {
  source = "./modules/frontend"

  name_prefix = local.name_prefix
}
