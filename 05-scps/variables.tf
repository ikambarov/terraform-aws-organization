variable "aws_region" {
  description = "AWS Region for AWS Organizations API calls."
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

variable "allowed_regions" {
  description = "AWS Regions allowed for workload accounts."
  type        = list(string)
  default     = ["us-east-1", "us-east-2"]
}

variable "global_service_action_exceptions" {
  description = "Global service actions exempted from the Region restriction SCP."
  type        = list(string)
  default = [
    "account:*",
    "aws-portal:*",
    "billing:*",
    "budgets:*",
    "ce:*",
    "cloudfront:*",
    "cur:*",
    "globalaccelerator:*",
    "health:*",
    "iam:*",
    "organizations:*",
    "route53:*",
    "route53domains:*",
    "shield:*",
    "sts:*",
    "support:*",
    "tax:*",
    "trustedadvisor:*",
    "waf:*",
    "wafv2:*",
  ]
}

variable "blocked_instance_family_patterns" {
  description = "EC2 instance type patterns blocked in workload accounts."
  type        = list(string)
  default     = ["c*", "p*", "g*", "inf*", "trn*", "x*", "u-*", "hpc*"]
}

variable "ec2_cloudwatch_agent_tag_key" {
  description = "Required EC2 tag key for CloudWatch Agent compliance behavior."
  type        = string
  default     = "CloudWatchAgent"
}

variable "allowed_cloudwatch_agent_tag_values" {
  description = "Allowed values for the CloudWatchAgent EC2 tag."
  type        = list(string)
  default     = ["enabled", "disabled"]
}

variable "ec2_ssm_managed_tag_key" {
  description = "Required EC2 tag key for SSM managed instance compliance behavior."
  type        = string
  default     = "SSMManaged"
}

variable "allowed_ssm_managed_tag_values" {
  description = "Allowed values for the SSMManaged EC2 tag."
  type        = list(string)
  default     = ["enabled", "disabled"]
}

variable "ec2_backup_tag_key" {
  description = "Required EC2 tag key for AWS Backup selection behavior."
  type        = string
  default     = "Backup"
}

variable "allowed_backup_tag_values" {
  description = "Allowed values for the Backup EC2 tag."
  type        = list(string)
  default     = ["daily", "weekly", "disabled"]
}

variable "s3_macie_scan_tag_key" {
  description = "Required S3 bucket tag key for Macie scan behavior."
  type        = string
  default     = "MacieScan"
}

variable "allowed_macie_scan_tag_values" {
  description = "Allowed values for the MacieScan S3 bucket tag."
  type        = list(string)
  default     = ["enabled", "disabled"]
}

variable "deny_unsupported_regions_policy_name" {
  description = "Name for the unsupported Regions SCP."
  type        = string
  default     = "DenyUnsupportedRegions"
}

variable "deny_expensive_ec2_policy_name" {
  description = "Name for the expensive EC2 instance family SCP."
  type        = string
  default     = "DenyExpensiveEc2InstanceFamilies"
}

variable "deny_unencrypted_ebs_policy_name" {
  description = "Name for the unencrypted EBS SCP."
  type        = string
  default     = "DenyUnencryptedEbs"
}

variable "require_ec2_tags_policy_name" {
  description = "Name for the mandatory EC2 tags SCP."
  type        = string
  default     = "RequireMandatoryEc2Tags"
}

variable "require_s3_macie_tag_policy_name" {
  description = "Name for the mandatory S3 MacieScan tag SCP."
  type        = string
  default     = "RequireMandatoryS3MacieScanTag"
}

variable "deny_iam_user_access_keys_policy_name" {
  description = "Name for the IAM user access key SCP."
  type        = string
  default     = "DenyIamUserAccessKeys"
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
