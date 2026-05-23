variable "aws_region" {
  description = "AWS Region used for Organizations API calls."
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
