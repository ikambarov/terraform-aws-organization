data "aws_partition" "current" {
  provider = aws.management
}

locals {
  foundational_security_best_practices_standard_arn = "arn:${data.aws_partition.current.partition}:securityhub:${var.aws_region}::standards/aws-foundational-security-best-practices/v/1.0.0"
  security_account_id                               = var.security_account_id
  workload_dev_account_id                           = var.workload_dev_account_id
  workload_prod_account_id                          = var.workload_prod_account_id
  security_account_role_arn                         = "arn:${data.aws_partition.current.partition}:iam::${local.security_account_id}:role/${var.member_account_role_name}"
  workload_dev_account_role_arn                     = "arn:${data.aws_partition.current.partition}:iam::${local.workload_dev_account_id}:role/${var.member_account_role_name}"
  workload_prod_account_role_arn                    = "arn:${data.aws_partition.current.partition}:iam::${local.workload_prod_account_id}:role/${var.member_account_role_name}"
}

resource "aws_organizations_aws_service_access" "guardduty" {
  provider = aws.management

  service_principal = "guardduty.amazonaws.com"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_organizations_aws_service_access" "securityhub" {
  provider = aws.management

  service_principal = "securityhub.amazonaws.com"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_guardduty_detector" "security" {
  provider = aws.security

  enable = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_guardduty_detector" "workload_dev" {
  provider = aws.workload_dev

  enable = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_guardduty_detector" "workload_prod" {
  provider = aws.workload_prod

  enable = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_guardduty_organization_admin_account" "security" {
  provider = aws.management

  admin_account_id = local.security_account_id

  depends_on = [
    aws_organizations_aws_service_access.guardduty,
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_guardduty_organization_configuration" "security" {
  provider = aws.security

  detector_id                      = aws_guardduty_detector.security.id
  auto_enable_organization_members = var.guardduty_auto_enable_organization_members

  depends_on = [
    aws_guardduty_organization_admin_account.security,
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_securityhub_organization_admin_account" "security" {
  provider = aws.management

  admin_account_id = local.security_account_id

  depends_on = [
    aws_organizations_aws_service_access.securityhub,
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_securityhub_account" "security" {
  provider = aws.security

  enable_default_standards = false

  depends_on = [
    aws_securityhub_organization_admin_account.security,
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_securityhub_account" "workload_dev" {
  provider = aws.workload_dev

  enable_default_standards = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_securityhub_account" "workload_prod" {
  provider = aws.workload_prod

  enable_default_standards = false

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_securityhub_organization_configuration" "security" {
  provider = aws.security

  auto_enable           = var.securityhub_auto_enable_new_accounts
  auto_enable_standards = "NONE"

  depends_on = [
    aws_securityhub_account.security,
  ]

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_securityhub_standards_subscription" "security_foundational_best_practices" {
  provider = aws.security

  standards_arn = local.foundational_security_best_practices_standard_arn

  depends_on = [
    aws_securityhub_account.security,
  ]
}

resource "aws_securityhub_standards_subscription" "workload_dev_foundational_best_practices" {
  provider = aws.workload_dev

  standards_arn = local.foundational_security_best_practices_standard_arn

  depends_on = [
    aws_securityhub_account.workload_dev,
  ]
}

resource "aws_securityhub_standards_subscription" "workload_prod_foundational_best_practices" {
  provider = aws.workload_prod

  standards_arn = local.foundational_security_best_practices_standard_arn

  depends_on = [
    aws_securityhub_account.workload_prod,
  ]
}
