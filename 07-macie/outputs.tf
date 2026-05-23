output "macie_admin_account_id" {
  description = "Delegated Macie administrator account ID."
  value       = aws_macie2_organization_admin_account.security.admin_account_id
}

output "macie_classification_job_id" {
  description = "Targeted daily Macie classification job ID."
  value       = aws_macie2_classification_job.targeted_tagged_buckets.job_id
}
