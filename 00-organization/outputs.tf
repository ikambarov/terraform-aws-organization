output "organization_id" {
  description = "Existing AWS Organization ID."
  value       = data.aws_organizations_organization.current.id
}

output "security_ou_id" {
  description = "Existing Security OU ID."
  value       = local.security_ou_id
}

output "workloads_ou_id" {
  description = "Existing Workloads OU ID."
  value       = local.workloads_ou_id
}

output "security_account_id" {
  description = "Existing security account ID."
  value       = local.security_account.id
}

output "workload_dev_account_id" {
  description = "Existing workload-dev account ID."
  value       = local.workload_dev_account.id
}

output "workload_prod_account_id" {
  description = "Existing workload-prod account ID."
  value       = local.workload_prod_account.id
}
