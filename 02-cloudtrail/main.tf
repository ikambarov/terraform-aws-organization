data "aws_partition" "current" {
  provider = aws.management
}

data "aws_caller_identity" "management" {
  provider = aws.management
}

data "aws_organizations_organization" "current" {
  provider = aws.management
}

locals {
  management_account_id     = data.aws_caller_identity.management.account_id
  security_account_id       = var.security_account_id
  security_account_role_arn = "arn:${data.aws_partition.current.partition}:iam::${local.security_account_id}:role/${var.member_account_role_name}"
  organization_id           = data.aws_organizations_organization.current.id
  cloudtrail_bucket_name    = coalesce(var.cloudtrail_bucket_name, "security-baseline-cloudtrail-${local.security_account_id}-${var.aws_region}")
  trail_arn                 = "arn:${data.aws_partition.current.partition}:cloudtrail:${var.aws_region}:${local.management_account_id}:trail/${var.cloudtrail_trail_name}"
}

data "aws_iam_policy_document" "cloudtrail_kms" {
  statement {
    sid     = "AllowSecurityAccountKeyAdministration"
    effect  = "Allow"
    actions = ["kms:*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${local.security_account_id}:root"]
    }

    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudTrailToDescribeKey"
    effect = "Allow"

    actions = [
      "kms:DescribeKey",
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudTrailToEncryptLogs"
    effect = "Allow"

    actions = [
      "kms:GenerateDataKey*",
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:*:${local.management_account_id}:trail/${var.cloudtrail_trail_name}"]
    }
  }
}

resource "aws_kms_key" "cloudtrail" {
  provider                = aws.security
  description             = "KMS key for organization CloudTrail log encryption."
  deletion_window_in_days = 30
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.cloudtrail_kms.json

}

resource "aws_kms_alias" "cloudtrail" {
  provider      = aws.security
  name          = var.cloudtrail_kms_alias
  target_key_id = aws_kms_key.cloudtrail.key_id
}

resource "aws_s3_bucket" "cloudtrail" {
  provider = aws.security
  bucket   = local.cloudtrail_bucket_name

}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  provider = aws.security
  bucket   = aws_s3_bucket.cloudtrail.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  provider = aws.security
  bucket   = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  provider = aws.security
  bucket   = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.cloudtrail.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  provider = aws.security
  bucket   = aws_s3_bucket.cloudtrail.id

  rule {
    id     = "expire-noncurrent-cloudtrail-log-versions"
    status = "Enabled"

    filter {
      prefix = ""
    }

    noncurrent_version_expiration {
      noncurrent_days = var.cloudtrail_log_retention_days
    }
  }
}

data "aws_iam_policy_document" "cloudtrail_bucket" {
  statement {
    sid    = "AllowCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }

  statement {
    sid    = "AllowCloudTrailLogDelivery"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["s3:PutObject"]
    resources = [
      "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${local.organization_id}/*",
      "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${local.management_account_id}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail" {
  provider = aws.security
  bucket   = aws_s3_bucket.cloudtrail.id
  policy   = data.aws_iam_policy_document.cloudtrail_bucket.json
}

resource "aws_organizations_aws_service_access" "cloudtrail" {
  provider          = aws.management
  service_principal = "cloudtrail.amazonaws.com"
}

resource "aws_cloudtrail" "organization" {
  provider = aws.management

  name                          = var.cloudtrail_trail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail.bucket
  s3_key_prefix                 = var.cloudtrail_s3_key_prefix
  kms_key_id                    = aws_kms_key.cloudtrail.arn
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  is_organization_trail         = true

  event_selector {
    include_management_events = true
    read_write_type           = "All"
  }

  depends_on = [
    aws_organizations_aws_service_access.cloudtrail,
    aws_s3_bucket_policy.cloudtrail,
  ]

}
