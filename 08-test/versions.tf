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
  region = var.aws_region

  assume_role {
    role_arn = local.workload_dev_account_role_arn
  }
}

provider "aws" {
  alias  = "identity_center"
  region = var.aws_region
}
