data "aws_partition" "current" {}

data "aws_organizations_organization" "current" {}

data "aws_organizations_organizational_units" "root" {
  parent_id = local.root_id
}

data "aws_organizations_organizational_unit_child_accounts" "root_child_ous" {
  for_each = {
    for ou in data.aws_organizations_organizational_units.root.children : ou.id => ou
  }

  parent_id = each.key
}

locals {
  root_id = data.aws_organizations_organization.current.roots[0].id

  root_child_account_ids_by_ou = {
    for ou_id, child_accounts in data.aws_organizations_organizational_unit_child_accounts.root_child_ous :
    ou_id => [for account in child_accounts.accounts : account.id]
  }

  workloads_ou = one([
    for ou in data.aws_organizations_organizational_units.root.children : ou
    if contains(local.root_child_account_ids_by_ou[ou.id], var.workload_dev_account_id) &&
    contains(local.root_child_account_ids_by_ou[ou.id], var.workload_prod_account_id)
  ])

  workloads_ou_id  = local.workloads_ou.id
  ec2_instance_arn = "arn:${data.aws_partition.current.partition}:ec2:*:*:instance/*"
  s3_bucket_arn    = "arn:${data.aws_partition.current.partition}:s3:::*"
}

resource "terraform_data" "enable_service_control_policies" {
  input = {
    root_id = local.root_id
  }

  triggers_replace = [
    local.root_id,
    "wait-for-scp-policy-type-enabled-v1",
  ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      set -euo pipefail
      root_id="${self.input.root_id}"
      aws organizations enable-policy-type --root-id "$root_id" --policy-type SERVICE_CONTROL_POLICY >/dev/null 2>&1 || true
      for _ in $(seq 1 30); do
        status=$(aws organizations list-roots --query "Roots[0].PolicyTypes[?Type=='SERVICE_CONTROL_POLICY'].Status | [0]" --output text)
        if [ "$status" = "ENABLED" ]; then
          exit 0
        fi
        sleep 10
      done
      echo "SERVICE_CONTROL_POLICY did not reach ENABLED within the expected time." >&2
      exit 1
    EOT
  }
}

resource "aws_organizations_policy" "deny_unsupported_regions" {
  name        = var.deny_unsupported_regions_policy_name
  description = "Deny workload account activity outside approved Regions while exempting global services."
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyUnsupportedRegions"
        Effect    = "Deny"
        NotAction = var.global_service_action_exceptions
        Resource  = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = var.allowed_regions
          }
        }
      },
    ]
  })

}

resource "aws_organizations_policy" "deny_expensive_ec2" {
  name        = var.deny_expensive_ec2_policy_name
  description = "Deny expensive EC2 instance families in workload accounts."
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyBlockedEc2InstanceFamilies"
        Effect   = "Deny"
        Action   = "ec2:RunInstances"
        Resource = "*"
        Condition = {
          StringLike = {
            "ec2:InstanceType" = var.blocked_instance_family_patterns
          }
        }
      },
    ]
  })

}

# SCPs cannot safely express "deny TCP/22 from 0.0.0.0/0 or ::/0" because
# AuthorizeSecurityGroupIngress does not expose CIDR, port, or protocol condition keys.
# Use AWS Config managed rules, Security Hub controls, or EventBridge remediation for this control.

resource "aws_organizations_policy" "deny_unencrypted_ebs" {
  name        = var.deny_unencrypted_ebs_policy_name
  description = "Deny unencrypted EBS volumes and unencrypted EBS-backed EC2 launches."
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyUnencryptedEbs"
        Effect = "Deny"
        Action = [
          "ec2:CreateVolume",
          "ec2:RunInstances",
        ]
        Resource = "*"
        Condition = {
          Bool = {
            "ec2:Encrypted" = "false"
          }
        }
      },
    ]
  })

}

resource "aws_organizations_policy" "require_ec2_tags" {
  name        = var.require_ec2_tags_policy_name
  description = "Require and protect EC2 CloudWatchAgent, SSMManaged, and Backup tags in workload accounts."
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyRunInstancesWithoutCloudWatchAgentTag"
        Effect   = "Deny"
        Action   = "ec2:RunInstances"
        Resource = local.ec2_instance_arn
        Condition = {
          Null = {
            "aws:RequestTag/${var.ec2_cloudwatch_agent_tag_key}" = "true"
          }
        }
      },
      {
        Sid      = "DenyRunInstancesWithInvalidCloudWatchAgentTag"
        Effect   = "Deny"
        Action   = "ec2:RunInstances"
        Resource = local.ec2_instance_arn
        Condition = {
          StringNotEquals = {
            "aws:RequestTag/${var.ec2_cloudwatch_agent_tag_key}" = var.allowed_cloudwatch_agent_tag_values
          }
        }
      },
      {
        Sid      = "DenyRunInstancesWithoutSsmManagedTag"
        Effect   = "Deny"
        Action   = "ec2:RunInstances"
        Resource = local.ec2_instance_arn
        Condition = {
          Null = {
            "aws:RequestTag/${var.ec2_ssm_managed_tag_key}" = "true"
          }
        }
      },
      {
        Sid      = "DenyRunInstancesWithInvalidSsmManagedTag"
        Effect   = "Deny"
        Action   = "ec2:RunInstances"
        Resource = local.ec2_instance_arn
        Condition = {
          StringNotEquals = {
            "aws:RequestTag/${var.ec2_ssm_managed_tag_key}" = var.allowed_ssm_managed_tag_values
          }
        }
      },
      {
        Sid      = "DenyRunInstancesWithoutBackupTag"
        Effect   = "Deny"
        Action   = "ec2:RunInstances"
        Resource = local.ec2_instance_arn
        Condition = {
          Null = {
            "aws:RequestTag/${var.ec2_backup_tag_key}" = "true"
          }
        }
      },
      {
        Sid      = "DenyRunInstancesWithInvalidBackupTag"
        Effect   = "Deny"
        Action   = "ec2:RunInstances"
        Resource = local.ec2_instance_arn
        Condition = {
          StringNotEquals = {
            "aws:RequestTag/${var.ec2_backup_tag_key}" = var.allowed_backup_tag_values
          }
        }
      },
      {
        Sid      = "DenyDeletingMandatoryEc2Tags"
        Effect   = "Deny"
        Action   = "ec2:DeleteTags"
        Resource = local.ec2_instance_arn
        Condition = {
          "ForAnyValue:StringEquals" = {
            "aws:TagKeys" = [
              var.ec2_cloudwatch_agent_tag_key,
              var.ec2_ssm_managed_tag_key,
              var.ec2_backup_tag_key,
            ]
          }
        }
      },
      {
        Sid      = "DenyChangingCloudWatchAgentToUnsupportedValue"
        Effect   = "Deny"
        Action   = "ec2:CreateTags"
        Resource = local.ec2_instance_arn
        Condition = {
          "ForAnyValue:StringEquals" = {
            "aws:TagKeys" = [var.ec2_cloudwatch_agent_tag_key]
          }
          StringNotEquals = {
            "aws:RequestTag/${var.ec2_cloudwatch_agent_tag_key}" = var.allowed_cloudwatch_agent_tag_values
          }
        }
      },
      {
        Sid      = "DenyChangingSsmManagedToUnsupportedValue"
        Effect   = "Deny"
        Action   = "ec2:CreateTags"
        Resource = local.ec2_instance_arn
        Condition = {
          "ForAnyValue:StringEquals" = {
            "aws:TagKeys" = [var.ec2_ssm_managed_tag_key]
          }
          StringNotEquals = {
            "aws:RequestTag/${var.ec2_ssm_managed_tag_key}" = var.allowed_ssm_managed_tag_values
          }
        }
      },
      {
        Sid      = "DenyChangingBackupToUnsupportedValue"
        Effect   = "Deny"
        Action   = "ec2:CreateTags"
        Resource = local.ec2_instance_arn
        Condition = {
          "ForAnyValue:StringEquals" = {
            "aws:TagKeys" = [var.ec2_backup_tag_key]
          }
          StringNotEquals = {
            "aws:RequestTag/${var.ec2_backup_tag_key}" = var.allowed_backup_tag_values
          }
        }
      },
    ]
  })

}

resource "aws_organizations_policy" "require_s3_macie_tag" {
  name        = var.require_s3_macie_tag_policy_name
  description = "Protect S3 MacieScan bucket tags where S3 APIs expose usable condition keys."
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyDeletingBucketTags"
        Effect   = "Deny"
        Action   = "s3:DeleteBucketTagging"
        Resource = "*"
      },
    ]
  })

}

resource "aws_organizations_policy" "deny_iam_user_access_keys" {
  name        = var.deny_iam_user_access_keys_policy_name
  description = "Deny IAM user access key creation and updates in workload accounts."
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyIamUserAccessKeys"
        Effect = "Deny"
        Action = [
          "iam:CreateAccessKey",
          "iam:UpdateAccessKey",
        ]
        Resource = "*"
      },
    ]
  })

}

resource "aws_organizations_policy_attachment" "deny_unsupported_regions" {
  policy_id = aws_organizations_policy.deny_unsupported_regions.id
  target_id = local.workloads_ou_id

  depends_on = [
    terraform_data.enable_service_control_policies,
  ]
}

resource "aws_organizations_policy_attachment" "deny_expensive_ec2" {
  policy_id = aws_organizations_policy.deny_expensive_ec2.id
  target_id = local.workloads_ou_id

  depends_on = [
    terraform_data.enable_service_control_policies,
  ]
}

resource "aws_organizations_policy_attachment" "deny_unencrypted_ebs" {
  policy_id = aws_organizations_policy.deny_unencrypted_ebs.id
  target_id = local.workloads_ou_id

  depends_on = [
    terraform_data.enable_service_control_policies,
  ]
}

resource "aws_organizations_policy_attachment" "require_ec2_tags" {
  policy_id = aws_organizations_policy.require_ec2_tags.id
  target_id = local.workloads_ou_id

  depends_on = [
    terraform_data.enable_service_control_policies,
  ]
}

resource "aws_organizations_policy_attachment" "require_s3_macie_tag" {
  policy_id = aws_organizations_policy.require_s3_macie_tag.id
  target_id = local.workloads_ou_id

  depends_on = [
    terraform_data.enable_service_control_policies,
  ]
}

resource "aws_organizations_policy_attachment" "deny_iam_user_access_keys" {
  policy_id = aws_organizations_policy.deny_iam_user_access_keys.id
  target_id = local.workloads_ou_id

  depends_on = [
    terraform_data.enable_service_control_policies,
  ]
}
