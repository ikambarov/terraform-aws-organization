output "public_access_block_disabled_bucket_name" {
  description = "S3 bucket with bucket-level public access block intentionally disabled."
  value       = aws_s3_bucket.public_access_block_disabled.bucket
}

output "macie_scan_enabled_bucket_name" {
  description = "S3 bucket tagged MacieScan = enabled and containing fake sensitive data."
  value       = aws_s3_bucket.macie_scan_enabled.bucket
}

output "sample_sensitive_data_object_key" {
  description = "Object key for the fake sensitive data sample."
  value       = aws_s3_object.sample_fake_sensitive_data.key
}

output "default_vpc_id" {
  description = "Default VPC ID used for EC2 test instances."
  value       = data.aws_vpc.default.id
}

output "default_subnet_id" {
  description = "Default subnet ID used for EC2 test instances."
  value       = data.aws_subnets.default.ids[0]
}

output "test_instance_ids" {
  description = "EC2 test instance IDs."
  value = {
    cloudwatch_agent_missing   = aws_instance.cloudwatch_agent_missing.id
    cloudwatch_agent_installed = aws_instance.cloudwatch_agent_installed.id
    ssm_unmanaged              = aws_instance.ssm_unmanaged.id
    ssm_managed                = aws_instance.ssm_managed.id
  }
}

output "identity_center_user_ids" {
  description = "Identity Store user IDs to pass into 01-identity-center."
  value = {
    user1 = aws_identitystore_user.user1.user_id
    user2 = aws_identitystore_user.user2.user_id
  }
}
