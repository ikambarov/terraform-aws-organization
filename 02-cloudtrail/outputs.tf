output "cloudtrail_bucket_name" {
  description = "Central CloudTrail S3 bucket name."
  value       = aws_s3_bucket.cloudtrail.bucket
}

output "cloudtrail_kms_key_arn" {
  description = "KMS key ARN used to encrypt CloudTrail logs."
  value       = aws_kms_key.cloudtrail.arn
}

output "cloudtrail_trail_arn" {
  description = "Organization CloudTrail ARN."
  value       = aws_cloudtrail.organization.arn
}
