variable "aws_region" {
  description = "AWS Region for workload-dev test resources."
  type        = string
  default     = "us-east-2"
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
  description = "Existing workload-prod account ID. Accepted from the shared root tfvars; not used by this module."
  type        = string
}

variable "management_account_role_arn" {
  description = "Role ARN Terraform assumes to create IAM Identity Center test users."
  type        = string
}

variable "member_account_role_name" {
  description = "Terraform execution role name used in member accounts."
  type        = string
  default     = "TerraformMemberExecutionRole"
}

variable "name_prefix" {
  description = "Prefix used for named test resources."
  type        = string
  default     = "security-baseline-test"
}

variable "public_access_block_disabled_bucket_name" {
  description = "Globally unique S3 bucket name for the bucket-level public access block disabled test bucket."
  type        = string
  default     = null
}

variable "macie_scan_enabled_bucket_name" {
  description = "Globally unique S3 bucket name for the MacieScan = enabled test bucket."
  type        = string
  default     = null
}

variable "force_destroy_test_buckets" {
  description = "Whether test buckets should be force destroyed during cleanup."
  type        = bool
  default     = true
}

variable "instance_type" {
  description = "Small EC2 instance type for test instances."
  type        = string
  default     = "t3.nano"
}

variable "amazon_linux_2023_ami_owner" {
  description = "AWS account ID for Amazon-owned Amazon Linux 2023 AMIs."
  type        = string
  default     = "137112412989"
}

variable "amazon_linux_2023_ami_name_pattern" {
  description = "AMI name filter for x86_64 Amazon Linux 2023."
  type        = string
  default     = "al2023-ami-2023*-kernel-6.1-x86_64"
}

variable "root_volume_size" {
  description = "Root EBS volume size in GiB for test EC2 instances."
  type        = number
  default     = 8
}

variable "cloudwatch_agent_role_name" {
  description = "Optional IAM role name for the CloudWatch Agent installed test instance."
  type        = string
  default     = null
}

variable "cloudwatch_agent_instance_profile_name" {
  description = "Optional IAM instance profile name for the CloudWatch Agent installed test instance."
  type        = string
  default     = null
}

variable "ssm_instance_role_name" {
  description = "Optional IAM role name for the SSM managed test instance."
  type        = string
  default     = null
}

variable "ssm_instance_profile_name" {
  description = "Optional IAM instance profile name for the SSM managed test instance."
  type        = string
  default     = null
}

variable "sample_sensitive_data_object_key" {
  description = "Object key for the fake sensitive data sample in the Macie test bucket."
  type        = string
  default     = "sample-fake-sensitive-data.txt"
}

variable "sample_sensitive_data_content" {
  description = "Fake sensitive data content used to exercise Macie discovery."
  type        = string
  default     = <<-EOT
    This file contains synthetic data for security baseline testing only.

    Example employee record:
    Name: Jane Example
    Email: jane.example@example.com
    SSN: 078-05-1120
    Visa test card: 4111 1111 1111 1111
    Mastercard test card: 5555 5555 5555 4444

    These are test values, not real personal or payment data.
  EOT
}

variable "user1" {
  description = "Identity Center test user assigned to SecurityAdmin by 01-identity-center."
  type = object({
    user_name    = string
    display_name = string
    given_name   = string
    family_name  = string
    email        = string
  })
}

variable "user2" {
  description = "Identity Center test user assigned to WorkloadDevAdmin and WorkloadProdAdmin by 01-identity-center."
  type = object({
    user_name    = string
    display_name = string
    given_name   = string
    family_name  = string
    email        = string
  })
}

variable "tags" {
  description = "Additional tags applied to test resources."
  type        = map(string)
  default     = {}
}
