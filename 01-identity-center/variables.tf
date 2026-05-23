variable "aws_region" {
  description = "AWS Region for IAM Identity Center administration."
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

variable "permission_set_session_duration" {
  description = "Session duration for administrator permission sets."
  type        = string
  default     = "PT4H"
}

variable "organization_admin_principal_id" {
  description = "Optional existing Identity Center principal ID to assign OrganizationAdmin in the management account."
  type        = string
  default     = null
}

variable "organization_admin_principal_type" {
  description = "Identity Center principal type for OrganizationAdmin assignment."
  type        = string
  default     = "USER"

  validation {
    condition     = contains(["USER", "GROUP"], var.organization_admin_principal_type)
    error_message = "organization_admin_principal_type must be USER or GROUP."
  }
}

variable "user1" {
  description = "Identity Center user assigned SecurityAdmin."
  type = object({
    user_name    = string
    display_name = string
    given_name   = string
    family_name  = string
    email        = string
  })
}

variable "user2" {
  description = "Identity Center user assigned WorkloadDevAdmin and WorkloadProdAdmin."
  type = object({
    user_name    = string
    display_name = string
    given_name   = string
    family_name  = string
    email        = string
  })
}
