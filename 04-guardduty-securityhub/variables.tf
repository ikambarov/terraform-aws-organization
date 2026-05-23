variable "aws_region" {
  description = "AWS Region for GuardDuty and Security Hub."
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

variable "guardduty_auto_enable_organization_members" {
  description = "GuardDuty organization auto-enable mode for organization members."
  type        = string
  default     = "NEW"

  validation {
    condition     = contains(["ALL", "NEW", "NONE"], var.guardduty_auto_enable_organization_members)
    error_message = "guardduty_auto_enable_organization_members must be ALL, NEW, or NONE."
  }
}

variable "securityhub_auto_enable_new_accounts" {
  description = "Whether Security Hub should be automatically enabled for new organization accounts."
  type        = bool
  default     = true
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
