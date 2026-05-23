variable "aws_region" {
  description = "Home Region for the organization CloudTrail trail."
  type        = string
  default     = "us-east-2"
}

variable "management_account_role_arn" {
  description = "Role ARN Terraform assumes in the management account."
  type        = string
}

variable "security_account_id" {
  description = "Existing security account ID."
  type        = string
}

variable "workload_dev_account_id" {
  description = "Existing workload-dev account ID. Accepted from the shared root tfvars; not used by this module."
  type        = string
}

variable "workload_prod_account_id" {
  description = "Existing workload-prod account ID. Accepted from the shared root tfvars; not used by this module."
  type        = string
}

variable "member_account_role_name" {
  description = "Terraform execution role name used in member accounts."
  type        = string
  default     = "TerraformMemberExecutionRole"
}

variable "cloudtrail_trail_name" {
  description = "Name for the organization CloudTrail trail."
  type        = string
  default     = "organization-management-events"
}

variable "cloudtrail_bucket_name" {
  description = "Name for the central CloudTrail log bucket in the security account."
  type        = string
  default     = null
}

variable "cloudtrail_kms_alias" {
  description = "KMS alias name for the CloudTrail log encryption key."
  type        = string
  default     = "alias/security-baseline-cloudtrail"
}

variable "cloudtrail_s3_key_prefix" {
  description = "Optional S3 key prefix for CloudTrail logs."
  type        = string
  default     = null
}

variable "cloudtrail_log_retention_days" {
  description = "Retention window before CloudTrail log object noncurrent versions expire."
  type        = number
  default     = 365
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
