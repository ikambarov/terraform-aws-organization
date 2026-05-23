output "permission_set_arns" {
  description = "IAM Identity Center permission set ARNs."
  value = {
    organization_admin  = aws_ssoadmin_permission_set.organization_admin.arn
    security_admin      = aws_ssoadmin_permission_set.security_admin.arn
    workload_dev_admin  = aws_ssoadmin_permission_set.workload_dev_admin.arn
    workload_prod_admin = aws_ssoadmin_permission_set.workload_prod_admin.arn
  }
}

output "user_ids" {
  description = "Identity Store user IDs used for account assignments."
  value = {
    user1 = data.aws_identitystore_user.user1.user_id
    user2 = data.aws_identitystore_user.user2.user_id
  }
}
