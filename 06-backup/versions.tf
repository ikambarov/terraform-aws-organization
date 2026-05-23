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
  alias  = "workload_dev"
  region = var.aws_region

  assume_role {
    role_arn = local.workload_dev_account_role_arn
  }
}

provider "aws" {
  alias  = "workload_prod"
  region = var.aws_region

  assume_role {
    role_arn = local.workload_prod_account_role_arn
  }
}
