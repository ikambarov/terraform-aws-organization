data "aws_partition" "current" {
  provider = aws.management
}

locals {
  security_account_id            = var.security_account_id
  workload_dev_account_id        = var.workload_dev_account_id
  workload_prod_account_id       = var.workload_prod_account_id
  security_account_role_arn      = "arn:${data.aws_partition.current.partition}:iam::${local.security_account_id}:role/${var.member_account_role_name}"
  workload_dev_account_role_arn  = "arn:${data.aws_partition.current.partition}:iam::${local.workload_dev_account_id}:role/${var.member_account_role_name}"
  workload_prod_account_role_arn = "arn:${data.aws_partition.current.partition}:iam::${local.workload_prod_account_id}:role/${var.member_account_role_name}"
  classification_job_name        = coalesce(var.classification_job_name, "daily-targeted-macie-scan")
}

resource "aws_organizations_aws_service_access" "macie" {
  provider = aws.management

  service_principal = "macie.amazonaws.com"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_macie2_account" "security" {
  provider = aws.security

  finding_publishing_frequency = var.macie_finding_publishing_frequency
  status                       = "ENABLED"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_macie2_account" "workload_dev" {
  provider = aws.workload_dev

  finding_publishing_frequency = var.macie_finding_publishing_frequency
  status                       = "ENABLED"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_macie2_account" "workload_prod" {
  provider = aws.workload_prod

  finding_publishing_frequency = var.macie_finding_publishing_frequency
  status                       = "ENABLED"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_macie2_organization_admin_account" "security" {
  provider = aws.management

  admin_account_id = local.security_account_id

  depends_on = [
    aws_organizations_aws_service_access.macie,
    aws_macie2_account.security,
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_macie2_organization_configuration" "security" {
  provider = aws.security

  auto_enable = true

  depends_on = [
    aws_macie2_organization_admin_account.security,
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_macie2_classification_job" "targeted_tagged_buckets" {
  provider = aws.security

  job_type            = "SCHEDULED"
  initial_run         = true
  name                = local.classification_job_name
  description         = "Daily targeted Macie scan for workload buckets tagged ${var.macie_scan_tag_key} = ${var.macie_scan_enabled_value}."
  sampling_percentage = var.sampling_percentage

  schedule_frequency {
    daily_schedule = true
  }

  s3_job_definition {
    bucket_criteria {
      includes {
        and {
          simple_criterion {
            comparator = "EQ"
            key        = "ACCOUNT_ID"
            values = [
              local.workload_dev_account_id,
              local.workload_prod_account_id,
            ]
          }
        }

        and {
          tag_criterion {
            comparator = "EQ"

            tag_values {
              key   = var.macie_scan_tag_key
              value = var.macie_scan_enabled_value
            }
          }
        }
      }
    }
  }

  depends_on = [
    aws_macie2_organization_configuration.security,
    aws_macie2_account.workload_dev,
    aws_macie2_account.workload_prod,
  ]
}
