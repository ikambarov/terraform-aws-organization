data "aws_partition" "current" {
  provider = aws.management
}

locals {
  backup_service_role_policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  workload_dev_account_id        = var.workload_dev_account_id
  workload_prod_account_id       = var.workload_prod_account_id
  workload_dev_account_role_arn  = "arn:${data.aws_partition.current.partition}:iam::${local.workload_dev_account_id}:role/${var.member_account_role_name}"
  workload_prod_account_role_arn = "arn:${data.aws_partition.current.partition}:iam::${local.workload_prod_account_id}:role/${var.member_account_role_name}"

  workload_dev_ec2_resources = [
    "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}:${local.workload_dev_account_id}:instance/*",
    "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}:${local.workload_dev_account_id}:volume/*",
  ]

  workload_prod_ec2_resources = [
    "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}:${local.workload_prod_account_id}:instance/*",
    "arn:${data.aws_partition.current.partition}:ec2:${var.aws_region}:${local.workload_prod_account_id}:volume/*",
  ]
}

data "aws_iam_policy_document" "backup_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "workload_dev_backup" {
  provider = aws.workload_dev

  name               = var.workload_dev_backup_role_name
  assume_role_policy = data.aws_iam_policy_document.backup_assume_role.json

}

resource "aws_iam_role" "workload_prod_backup" {
  provider = aws.workload_prod

  name               = var.workload_prod_backup_role_name
  assume_role_policy = data.aws_iam_policy_document.backup_assume_role.json

}

resource "aws_iam_role_policy_attachment" "workload_dev_backup" {
  provider = aws.workload_dev

  role       = aws_iam_role.workload_dev_backup.name
  policy_arn = local.backup_service_role_policy_arn
}

resource "aws_iam_role_policy_attachment" "workload_prod_backup" {
  provider = aws.workload_prod

  role       = aws_iam_role.workload_prod_backup.name
  policy_arn = local.backup_service_role_policy_arn
}

resource "aws_backup_vault" "workload_dev" {
  provider = aws.workload_dev

  name        = var.workload_dev_backup_vault_name
  kms_key_arn = var.workload_dev_backup_vault_kms_key_arn

}

resource "aws_backup_vault" "workload_prod" {
  provider = aws.workload_prod

  name        = var.workload_prod_backup_vault_name
  kms_key_arn = var.workload_prod_backup_vault_kms_key_arn

}

resource "aws_backup_plan" "workload_dev_daily" {
  provider = aws.workload_dev

  name = var.dev_daily_backup_plan_name

  rule {
    rule_name         = var.dev_daily_backup_plan_name
    target_vault_name = aws_backup_vault.workload_dev.name
    schedule          = var.daily_backup_schedule

    lifecycle {
      delete_after = var.dev_daily_retention_days
    }
  }

}

resource "aws_backup_plan" "workload_dev_weekly" {
  provider = aws.workload_dev

  name = var.dev_weekly_backup_plan_name

  rule {
    rule_name         = var.dev_weekly_backup_plan_name
    target_vault_name = aws_backup_vault.workload_dev.name
    schedule          = var.weekly_backup_schedule

    lifecycle {
      delete_after = var.dev_weekly_retention_days
    }
  }

}

resource "aws_backup_plan" "workload_prod_daily" {
  provider = aws.workload_prod

  name = var.prod_daily_backup_plan_name

  rule {
    rule_name         = var.prod_daily_backup_plan_name
    target_vault_name = aws_backup_vault.workload_prod.name
    schedule          = var.daily_backup_schedule

    lifecycle {
      delete_after = var.prod_daily_retention_days
    }
  }

}

resource "aws_backup_plan" "workload_prod_weekly" {
  provider = aws.workload_prod

  name = var.prod_weekly_backup_plan_name

  rule {
    rule_name         = var.prod_weekly_backup_plan_name
    target_vault_name = aws_backup_vault.workload_prod.name
    schedule          = var.weekly_backup_schedule

    lifecycle {
      delete_after = var.prod_weekly_retention_days
    }
  }

}

resource "aws_backup_selection" "workload_dev_daily" {
  provider = aws.workload_dev

  name         = "${var.dev_daily_backup_plan_name}-selection"
  iam_role_arn = aws_iam_role.workload_dev_backup.arn
  plan_id      = aws_backup_plan.workload_dev_daily.id
  resources    = local.workload_dev_ec2_resources

  selection_tag {
    type  = "STRINGEQUALS"
    key   = var.backup_tag_key
    value = var.daily_backup_tag_value
  }
}

resource "aws_backup_selection" "workload_dev_weekly" {
  provider = aws.workload_dev

  name         = "${var.dev_weekly_backup_plan_name}-selection"
  iam_role_arn = aws_iam_role.workload_dev_backup.arn
  plan_id      = aws_backup_plan.workload_dev_weekly.id
  resources    = local.workload_dev_ec2_resources

  selection_tag {
    type  = "STRINGEQUALS"
    key   = var.backup_tag_key
    value = var.weekly_backup_tag_value
  }
}

resource "aws_backup_selection" "workload_prod_daily" {
  provider = aws.workload_prod

  name         = "${var.prod_daily_backup_plan_name}-selection"
  iam_role_arn = aws_iam_role.workload_prod_backup.arn
  plan_id      = aws_backup_plan.workload_prod_daily.id
  resources    = local.workload_prod_ec2_resources

  selection_tag {
    type  = "STRINGEQUALS"
    key   = var.backup_tag_key
    value = var.daily_backup_tag_value
  }
}

resource "aws_backup_selection" "workload_prod_weekly" {
  provider = aws.workload_prod

  name         = "${var.prod_weekly_backup_plan_name}-selection"
  iam_role_arn = aws_iam_role.workload_prod_backup.arn
  plan_id      = aws_backup_plan.workload_prod_weekly.id
  resources    = local.workload_prod_ec2_resources

  selection_tag {
    type  = "STRINGEQUALS"
    key   = var.backup_tag_key
    value = var.weekly_backup_tag_value
  }
}
