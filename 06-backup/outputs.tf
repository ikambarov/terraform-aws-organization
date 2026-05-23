output "backup_vault_names" {
  description = "AWS Backup vault names."
  value = {
    workload_dev  = aws_backup_vault.workload_dev.name
    workload_prod = aws_backup_vault.workload_prod.name
  }
}

output "backup_plan_ids" {
  description = "AWS Backup plan IDs."
  value = {
    workload_dev_daily   = aws_backup_plan.workload_dev_daily.id
    workload_dev_weekly  = aws_backup_plan.workload_dev_weekly.id
    workload_prod_daily  = aws_backup_plan.workload_prod_daily.id
    workload_prod_weekly = aws_backup_plan.workload_prod_weekly.id
  }
}
