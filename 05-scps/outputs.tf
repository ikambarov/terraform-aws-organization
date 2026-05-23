output "scp_policy_ids" {
  description = "SCP policy IDs attached to the Workloads OU."
  value = {
    deny_unsupported_regions          = aws_organizations_policy.deny_unsupported_regions.id
    deny_expensive_ec2_instance_types = aws_organizations_policy.deny_expensive_ec2.id
    deny_unencrypted_ebs              = aws_organizations_policy.deny_unencrypted_ebs.id
    require_ec2_tags                  = aws_organizations_policy.require_ec2_tags.id
    require_s3_macie_scan_tag         = aws_organizations_policy.require_s3_macie_tag.id
    deny_iam_user_access_keys         = aws_organizations_policy.deny_iam_user_access_keys.id
  }
}

output "workloads_ou_policy_attachment_ids" {
  description = "SCP attachment IDs for the Workloads OU."
  value = {
    deny_unsupported_regions          = aws_organizations_policy_attachment.deny_unsupported_regions.id
    deny_expensive_ec2_instance_types = aws_organizations_policy_attachment.deny_expensive_ec2.id
    deny_unencrypted_ebs              = aws_organizations_policy_attachment.deny_unencrypted_ebs.id
    require_ec2_tags                  = aws_organizations_policy_attachment.require_ec2_tags.id
    require_s3_macie_scan_tag         = aws_organizations_policy_attachment.require_s3_macie_tag.id
    deny_iam_user_access_keys         = aws_organizations_policy_attachment.deny_iam_user_access_keys.id
  }
}
