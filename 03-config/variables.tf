variable "aws_region" {
  description = "AWS Region for AWS Config recorders, rules, and aggregator."
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

variable "config_delivery_bucket_name" {
  description = "S3 bucket name used by workload account AWS Config delivery channels."
  type        = string
  default     = null
}

variable "config_delivery_s3_key_prefix" {
  description = "Optional prefix for AWS Config delivery objects."
  type        = string
  default     = null
}

variable "configuration_recorder_name" {
  description = "AWS Config recorder name in each workload account."
  type        = string
  default     = "default"
}

variable "delivery_channel_name" {
  description = "AWS Config delivery channel name in each workload account."
  type        = string
  default     = "default"
}

variable "workload_dev_config_role_name" {
  description = "IAM role name for AWS Config in the workload-dev account."
  type        = string
  default     = "security-baseline-config-dev-role"
}

variable "workload_prod_config_role_name" {
  description = "IAM role name for AWS Config in the workload-prod account."
  type        = string
  default     = "security-baseline-config-prod-role"
}

variable "config_aggregator_name" {
  description = "AWS Config aggregator name in the security account."
  type        = string
  default     = "security-baseline-config-aggregator"
}

variable "cloudwatch_agent_tag_key" {
  description = "Tag key used to indicate CloudWatch Agent compliance expectations."
  type        = string
  default     = "CloudWatchAgent"
}

variable "cloudwatch_agent_enabled_value" {
  description = "Tag value indicating CloudWatch Agent is required."
  type        = string
  default     = "enabled"
}

variable "cloudwatch_agent_disabled_value" {
  description = "Tag value indicating CloudWatch Agent is intentionally excluded."
  type        = string
  default     = "disabled"
}

variable "cloudwatch_agent_application_names" {
  description = "SSM Inventory application names accepted as CloudWatch Agent installed."
  type        = list(string)
  default     = ["amazon-cloudwatch-agent"]
}

variable "ssm_managed_tag_key" {
  description = "Tag key used to indicate SSM managed instance compliance expectations."
  type        = string
  default     = "SSMManaged"
}

variable "ssm_managed_enabled_value" {
  description = "Tag value indicating SSM managed instance compliance is required."
  type        = string
  default     = "enabled"
}

variable "ssm_managed_disabled_value" {
  description = "Tag value indicating an instance is intentionally excluded from SSM managed instance compliance checks."
  type        = string
  default     = "disabled"
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
