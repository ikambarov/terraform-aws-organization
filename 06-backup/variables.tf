variable "aws_region" {
  description = "AWS Region for AWS Backup resources."
  type        = string
  default     = "us-east-2"
}

variable "management_account_role_arn" {
  description = "Role ARN Terraform assumes in the management account."
  type        = string
}

variable "security_account_id" {
  description = "Existing security account ID. Accepted from the shared root tfvars; not used by this module."
  type        = string
}

variable "workload_dev_account_id" {
  description = "Existing workload-dev account ID."
  type        = string
}

variable "workload_prod_account_id" {
  description = "Existing workload-prod account ID."
  type        = string
}

variable "member_account_role_name" {
  description = "Terraform execution role name used in member accounts."
  type        = string
  default     = "TerraformMemberExecutionRole"
}

variable "backup_tag_key" {
  description = "EC2/EBS tag key used for backup selection."
  type        = string
  default     = "Backup"
}

variable "daily_backup_tag_value" {
  description = "Tag value selecting EC2/EBS resources for daily backup."
  type        = string
  default     = "daily"
}

variable "weekly_backup_tag_value" {
  description = "Tag value selecting EC2/EBS resources for weekly backup."
  type        = string
  default     = "weekly"
}

variable "workload_dev_backup_role_name" {
  description = "AWS Backup IAM role name in workload-dev."
  type        = string
  default     = "security-baseline-backup-dev-role"
}

variable "workload_prod_backup_role_name" {
  description = "AWS Backup IAM role name in workload-prod."
  type        = string
  default     = "security-baseline-backup-prod-role"
}

variable "workload_dev_backup_vault_name" {
  description = "AWS Backup vault name in workload-dev."
  type        = string
  default     = "security-baseline-dev-backup-vault"
}

variable "workload_prod_backup_vault_name" {
  description = "AWS Backup vault name in workload-prod."
  type        = string
  default     = "security-baseline-prod-backup-vault"
}

variable "workload_dev_backup_vault_kms_key_arn" {
  description = "Optional KMS key ARN for the workload-dev backup vault."
  type        = string
  default     = null
}

variable "workload_prod_backup_vault_kms_key_arn" {
  description = "Optional KMS key ARN for the workload-prod backup vault."
  type        = string
  default     = null
}

variable "dev_daily_backup_plan_name" {
  description = "Daily backup plan name for workload-dev EC2/EBS resources."
  type        = string
  default     = "dev-ec2-daily-backup"
}

variable "dev_weekly_backup_plan_name" {
  description = "Weekly backup plan name for workload-dev EC2/EBS resources."
  type        = string
  default     = "dev-ec2-weekly-backup"
}

variable "prod_daily_backup_plan_name" {
  description = "Daily backup plan name for workload-prod EC2/EBS resources."
  type        = string
  default     = "prod-ec2-daily-backup"
}

variable "prod_weekly_backup_plan_name" {
  description = "Weekly backup plan name for workload-prod EC2/EBS resources."
  type        = string
  default     = "prod-ec2-weekly-backup"
}

variable "daily_backup_schedule" {
  description = "Cron expression for daily backups."
  type        = string
  default     = "cron(0 5 ? * * *)"
}

variable "weekly_backup_schedule" {
  description = "Cron expression for weekly backups."
  type        = string
  default     = "cron(0 6 ? * SUN *)"
}

variable "dev_daily_retention_days" {
  description = "Retention in days for workload-dev daily backups."
  type        = number
  default     = 7
}

variable "dev_weekly_retention_days" {
  description = "Retention in days for workload-dev weekly backups."
  type        = number
  default     = 30
}

variable "prod_daily_retention_days" {
  description = "Retention in days for workload-prod daily backups."
  type        = number
  default     = 30
}

variable "prod_weekly_retention_days" {
  description = "Retention in days for workload-prod weekly backups."
  type        = number
  default     = 90
}

variable "user1" {
  description = "Accepted from the shared root tfvars; not used by this module."
  type        = any
  default     = null
}

variable "user2" {
  description = "Accepted from the shared root tfvars; not used by this module."
  type        = any
  default     = null
}
