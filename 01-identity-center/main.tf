data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

data "aws_ssoadmin_instances" "current" {}

data "aws_identitystore_user" "user1" {
  identity_store_id = local.identity_store_id

  alternate_identifier {
    unique_attribute {
      attribute_path  = "UserName"
      attribute_value = var.user1.user_name
    }
  }
}

data "aws_identitystore_user" "user2" {
  identity_store_id = local.identity_store_id

  alternate_identifier {
    unique_attribute {
      attribute_path  = "UserName"
      attribute_value = var.user2.user_name
    }
  }
}

locals {
  identity_center_instance_arn = one(data.aws_ssoadmin_instances.current.arns)
  identity_store_id            = one(data.aws_ssoadmin_instances.current.identity_store_ids)
  administrator_access_arn     = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AdministratorAccess"

  management_account_id    = data.aws_caller_identity.current.account_id
  security_account_id      = var.security_account_id
  workload_dev_account_id  = var.workload_dev_account_id
  workload_prod_account_id = var.workload_prod_account_id
}

resource "aws_ssoadmin_permission_set" "organization_admin" {
  name             = "OrganizationAdmin"
  description      = "Administrative access for the AWS Organizations management account."
  instance_arn     = local.identity_center_instance_arn
  session_duration = var.permission_set_session_duration

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ssoadmin_permission_set" "security_admin" {
  name             = "SecurityAdmin"
  description      = "Administrative access for the centralized security account."
  instance_arn     = local.identity_center_instance_arn
  session_duration = var.permission_set_session_duration

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ssoadmin_permission_set" "workload_dev_admin" {
  name             = "WorkloadDevAdmin"
  description      = "Administrative access for the workload-dev account."
  instance_arn     = local.identity_center_instance_arn
  session_duration = var.permission_set_session_duration

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ssoadmin_permission_set" "workload_prod_admin" {
  name             = "WorkloadProdAdmin"
  description      = "Administrative access for the workload-prod account."
  instance_arn     = local.identity_center_instance_arn
  session_duration = var.permission_set_session_duration

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ssoadmin_managed_policy_attachment" "organization_admin" {
  instance_arn       = local.identity_center_instance_arn
  managed_policy_arn = local.administrator_access_arn
  permission_set_arn = aws_ssoadmin_permission_set.organization_admin.arn
}

resource "aws_ssoadmin_managed_policy_attachment" "security_admin" {
  instance_arn       = local.identity_center_instance_arn
  managed_policy_arn = local.administrator_access_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_admin.arn
}

resource "aws_ssoadmin_managed_policy_attachment" "workload_dev_admin" {
  instance_arn       = local.identity_center_instance_arn
  managed_policy_arn = local.administrator_access_arn
  permission_set_arn = aws_ssoadmin_permission_set.workload_dev_admin.arn
}

resource "aws_ssoadmin_managed_policy_attachment" "workload_prod_admin" {
  instance_arn       = local.identity_center_instance_arn
  managed_policy_arn = local.administrator_access_arn
  permission_set_arn = aws_ssoadmin_permission_set.workload_prod_admin.arn
}

resource "aws_ssoadmin_account_assignment" "organization_admin" {
  count = var.organization_admin_principal_id == null ? 0 : 1

  instance_arn       = local.identity_center_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.organization_admin.arn
  principal_id       = var.organization_admin_principal_id
  principal_type     = var.organization_admin_principal_type
  target_id          = local.management_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "security_admin_user1" {
  instance_arn       = local.identity_center_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.security_admin.arn
  principal_id       = data.aws_identitystore_user.user1.user_id
  principal_type     = "USER"
  target_id          = local.security_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "workload_dev_admin_user2" {
  instance_arn       = local.identity_center_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.workload_dev_admin.arn
  principal_id       = data.aws_identitystore_user.user2.user_id
  principal_type     = "USER"
  target_id          = local.workload_dev_account_id
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "workload_prod_admin_user2" {
  instance_arn       = local.identity_center_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.workload_prod_admin.arn
  principal_id       = data.aws_identitystore_user.user2.user_id
  principal_type     = "USER"
  target_id          = local.workload_prod_account_id
  target_type        = "AWS_ACCOUNT"
}
