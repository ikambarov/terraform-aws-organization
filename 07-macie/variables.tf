variable "aws_region" {
  description = "AWS Region for Macie resources."
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

variable "macie_finding_publishing_frequency" {
  description = "Frequency for publishing Macie policy finding updates."
  type        = string
  default     = "SIX_HOURS"

  validation {
    condition     = contains(["FIFTEEN_MINUTES", "ONE_HOUR", "SIX_HOURS"], var.macie_finding_publishing_frequency)
    error_message = "macie_finding_publishing_frequency must be FIFTEEN_MINUTES, ONE_HOUR, or SIX_HOURS."
  }
}

variable "macie_scan_tag_key" {
  description = "S3 bucket tag key used to select buckets for targeted Macie scans."
  type        = string
  default     = "MacieScan"
}

variable "macie_scan_enabled_value" {
  description = "Tag value indicating a bucket is eligible for targeted Macie scans."
  type        = string
  default     = "enabled"
}

variable "macie_scan_disabled_value" {
  description = "Tag value indicating a bucket is intentionally excluded from targeted Macie scans."
  type        = string
  default     = "disabled"
}

variable "classification_job_name" {
  description = "Macie classification job name for workload buckets tagged MacieScan = enabled."
  type        = string
  default     = null
}

variable "sampling_percentage" {
  description = "Percentage of eligible objects for each targeted Macie classification job."
  type        = number
  default     = 100

  validation {
    condition     = var.sampling_percentage >= 1 && var.sampling_percentage <= 100
    error_message = "sampling_percentage must be between 1 and 100."
  }
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
