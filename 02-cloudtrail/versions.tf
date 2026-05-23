terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  alias  = "management"
  region = var.aws_region
}

provider "aws" {
  alias  = "security"
  region = var.aws_region

  assume_role {
    role_arn = local.security_account_role_arn
  }
}
