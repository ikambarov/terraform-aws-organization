data "aws_partition" "current" {
  provider = aws.management
}

locals {
  config_service_role_policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWS_ConfigRole"
  security_account_id            = var.security_account_id
  workload_dev_account_id        = var.workload_dev_account_id
  workload_prod_account_id       = var.workload_prod_account_id
  security_account_role_arn      = "arn:${data.aws_partition.current.partition}:iam::${local.security_account_id}:role/${var.member_account_role_name}"
  workload_dev_account_role_arn  = "arn:${data.aws_partition.current.partition}:iam::${local.workload_dev_account_id}:role/${var.member_account_role_name}"
  workload_prod_account_role_arn = "arn:${data.aws_partition.current.partition}:iam::${local.workload_prod_account_id}:role/${var.member_account_role_name}"
  config_delivery_bucket_name    = coalesce(var.config_delivery_bucket_name, "security-baseline-config-${local.security_account_id}-${var.aws_region}")
  config_delivery_bucket_arn     = "arn:${data.aws_partition.current.partition}:s3:::${local.config_delivery_bucket_name}"

  config_delivery_object_arns = var.config_delivery_s3_key_prefix == null ? [
    "${local.config_delivery_bucket_arn}/AWSLogs/*/Config/*",
    ] : [
    "${local.config_delivery_bucket_arn}/${var.config_delivery_s3_key_prefix}/AWSLogs/*/Config/*",
  ]
}

data "aws_iam_policy_document" "config_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "config_delivery" {
  statement {
    sid     = "AllowConfigBucketAclCheck"
    effect  = "Allow"
    actions = ["s3:GetBucketAcl"]

    resources = [
      local.config_delivery_bucket_arn,
    ]
  }

  statement {
    sid     = "AllowConfigDelivery"
    effect  = "Allow"
    actions = ["s3:PutObject"]

    resources = local.config_delivery_object_arns

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

data "archive_file" "s3_macie_scan_tag_check" {
  type        = "zip"
  source_file = "${path.module}/lambda_s3_macie_scan_tag_check.py"
  output_path = "${path.module}/.terraform/s3_macie_scan_tag_check.zip"
}

data "archive_file" "cloudwatch_agent_check" {
  type        = "zip"
  source_file = "${path.module}/lambda_cloudwatch_agent_check.py"
  output_path = "${path.module}/.terraform/cloudwatch_agent_check.zip"
}

data "archive_file" "ssm_managed_check" {
  type        = "zip"
  source_file = "${path.module}/lambda_ssm_managed_check.py"
  output_path = "${path.module}/.terraform/ssm_managed_check.zip"
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "s3_macie_scan_tag_check_lambda" {
  statement {
    sid    = "AllowLambdaLogging"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:*:log-group:/aws/lambda/*"]
  }

  statement {
    sid    = "AllowConfigEvaluations"
    effect = "Allow"

    actions = [
      "config:PutEvaluations",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowS3TagRead"
    effect = "Allow"

    actions = [
      "s3:GetBucketTagging",
      "s3:ListAllMyBuckets",
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "cloudwatch_agent_check_lambda" {
  statement {
    sid    = "AllowLambdaLogging"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:${data.aws_partition.current.partition}:logs:${var.aws_region}:*:log-group:/aws/lambda/*"]
  }

  statement {
    sid    = "AllowConfigEvaluations"
    effect = "Allow"

    actions = [
      "config:PutEvaluations",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowEc2AndSsmRead"
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ssm:DescribeInstanceInformation",
      "ssm:GetCommandInvocation",
      "ssm:SendCommand",
    ]

    resources = ["*"]
  }

}

resource "aws_s3_bucket" "config_delivery" {
  provider = aws.security
  bucket   = local.config_delivery_bucket_name

}

resource "aws_s3_bucket_versioning" "config_delivery" {
  provider = aws.security
  bucket   = aws_s3_bucket.config_delivery.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "config_delivery" {
  provider = aws.security
  bucket   = aws_s3_bucket.config_delivery.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config_delivery" {
  provider = aws.security
  bucket   = aws_s3_bucket.config_delivery.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_iam_role" "workload_dev_config" {
  provider = aws.workload_dev

  name               = var.workload_dev_config_role_name
  assume_role_policy = data.aws_iam_policy_document.config_assume_role.json

}

resource "aws_iam_role" "workload_prod_config" {
  provider = aws.workload_prod

  name               = var.workload_prod_config_role_name
  assume_role_policy = data.aws_iam_policy_document.config_assume_role.json

}

resource "aws_iam_role_policy_attachment" "workload_dev_config" {
  provider = aws.workload_dev

  role       = aws_iam_role.workload_dev_config.name
  policy_arn = local.config_service_role_policy_arn
}

resource "aws_iam_role_policy_attachment" "workload_prod_config" {
  provider = aws.workload_prod

  role       = aws_iam_role.workload_prod_config.name
  policy_arn = local.config_service_role_policy_arn
}

resource "aws_iam_role_policy" "workload_dev_config_delivery" {
  provider = aws.workload_dev

  name   = "aws-config-delivery"
  role   = aws_iam_role.workload_dev_config.id
  policy = data.aws_iam_policy_document.config_delivery.json
}

resource "aws_iam_role_policy" "workload_prod_config_delivery" {
  provider = aws.workload_prod

  name   = "aws-config-delivery"
  role   = aws_iam_role.workload_prod_config.id
  policy = data.aws_iam_policy_document.config_delivery.json
}

data "aws_iam_policy_document" "config_delivery_bucket" {
  statement {
    sid     = "AllowWorkloadConfigBucketAclCheck"
    effect  = "Allow"
    actions = ["s3:GetBucketAcl"]

    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.workload_dev_config.arn,
        aws_iam_role.workload_prod_config.arn,
      ]
    }

    resources = [
      aws_s3_bucket.config_delivery.arn,
    ]
  }

  statement {
    sid     = "AllowWorkloadConfigDelivery"
    effect  = "Allow"
    actions = ["s3:PutObject"]

    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.workload_dev_config.arn,
        aws_iam_role.workload_prod_config.arn,
      ]
    }

    resources = local.config_delivery_object_arns

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "config_delivery" {
  provider = aws.security
  bucket   = aws_s3_bucket.config_delivery.id
  policy   = data.aws_iam_policy_document.config_delivery_bucket.json
}

resource "aws_config_configuration_recorder" "workload_dev" {
  provider = aws.workload_dev

  name     = var.configuration_recorder_name
  role_arn = aws_iam_role.workload_dev_config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.workload_dev_config,
    aws_iam_role_policy.workload_dev_config_delivery,
  ]

}

resource "aws_config_configuration_recorder" "workload_prod" {
  provider = aws.workload_prod

  name     = var.configuration_recorder_name
  role_arn = aws_iam_role.workload_prod_config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.workload_prod_config,
    aws_iam_role_policy.workload_prod_config_delivery,
  ]

}

resource "aws_config_delivery_channel" "workload_dev" {
  provider = aws.workload_dev

  name           = var.delivery_channel_name
  s3_bucket_name = local.config_delivery_bucket_name
  s3_key_prefix  = var.config_delivery_s3_key_prefix

  depends_on = [
    aws_config_configuration_recorder.workload_dev,
    aws_s3_bucket_policy.config_delivery,
  ]
}

resource "aws_config_delivery_channel" "workload_prod" {
  provider = aws.workload_prod

  name           = var.delivery_channel_name
  s3_bucket_name = local.config_delivery_bucket_name
  s3_key_prefix  = var.config_delivery_s3_key_prefix

  depends_on = [
    aws_config_configuration_recorder.workload_prod,
    aws_s3_bucket_policy.config_delivery,
  ]
}

resource "aws_config_configuration_recorder_status" "workload_dev" {
  provider = aws.workload_dev

  name       = aws_config_configuration_recorder.workload_dev.name
  is_enabled = true

  depends_on = [
    aws_config_delivery_channel.workload_dev,
  ]
}

resource "aws_config_configuration_recorder_status" "workload_prod" {
  provider = aws.workload_prod

  name       = aws_config_configuration_recorder.workload_prod.name
  is_enabled = true

  depends_on = [
    aws_config_delivery_channel.workload_prod,
  ]
}

resource "aws_iam_role" "workload_dev_s3_macie_scan_tag_check_lambda" {
  provider = aws.workload_dev

  name               = "security-baseline-s3-macie-tag-config-rule"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

}

resource "aws_iam_role" "workload_prod_s3_macie_scan_tag_check_lambda" {
  provider = aws.workload_prod

  name               = "security-baseline-s3-macie-tag-config-rule"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

}

resource "aws_iam_role_policy" "workload_dev_s3_macie_scan_tag_check_lambda" {
  provider = aws.workload_dev

  name   = "s3-macie-scan-tag-config-rule"
  role   = aws_iam_role.workload_dev_s3_macie_scan_tag_check_lambda.id
  policy = data.aws_iam_policy_document.s3_macie_scan_tag_check_lambda.json
}

resource "aws_iam_role_policy" "workload_prod_s3_macie_scan_tag_check_lambda" {
  provider = aws.workload_prod

  name   = "s3-macie-scan-tag-config-rule"
  role   = aws_iam_role.workload_prod_s3_macie_scan_tag_check_lambda.id
  policy = data.aws_iam_policy_document.s3_macie_scan_tag_check_lambda.json
}

resource "aws_lambda_function" "workload_dev_s3_macie_scan_tag_check" {
  provider = aws.workload_dev

  function_name    = "security-baseline-s3-macie-tag-config-rule"
  role             = aws_iam_role.workload_dev_s3_macie_scan_tag_check_lambda.arn
  handler          = "lambda_s3_macie_scan_tag_check.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.s3_macie_scan_tag_check.output_path
  source_code_hash = data.archive_file.s3_macie_scan_tag_check.output_base64sha256
  timeout          = 60

  depends_on = [
    aws_iam_role_policy.workload_dev_s3_macie_scan_tag_check_lambda,
  ]

}

resource "aws_lambda_function" "workload_prod_s3_macie_scan_tag_check" {
  provider = aws.workload_prod

  function_name    = "security-baseline-s3-macie-tag-config-rule"
  role             = aws_iam_role.workload_prod_s3_macie_scan_tag_check_lambda.arn
  handler          = "lambda_s3_macie_scan_tag_check.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.s3_macie_scan_tag_check.output_path
  source_code_hash = data.archive_file.s3_macie_scan_tag_check.output_base64sha256
  timeout          = 60

  depends_on = [
    aws_iam_role_policy.workload_prod_s3_macie_scan_tag_check_lambda,
  ]

}

resource "aws_lambda_permission" "workload_dev_allow_config_s3_macie_scan_tag_check" {
  provider = aws.workload_dev

  statement_id  = "AllowExecutionFromConfig"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.workload_dev_s3_macie_scan_tag_check.function_name
  principal     = "config.amazonaws.com"
}

resource "aws_lambda_permission" "workload_prod_allow_config_s3_macie_scan_tag_check" {
  provider = aws.workload_prod

  statement_id  = "AllowExecutionFromConfig"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.workload_prod_s3_macie_scan_tag_check.function_name
  principal     = "config.amazonaws.com"
}

resource "aws_iam_role" "workload_dev_cloudwatch_agent_check_lambda" {
  provider = aws.workload_dev

  name               = "security-baseline-cloudwatch-agent-config-rule"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

}

resource "aws_iam_role" "workload_prod_cloudwatch_agent_check_lambda" {
  provider = aws.workload_prod

  name               = "security-baseline-cloudwatch-agent-config-rule"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json

}

resource "aws_iam_role_policy" "workload_dev_cloudwatch_agent_check_lambda" {
  provider = aws.workload_dev

  name   = "cloudwatch-agent-config-rule"
  role   = aws_iam_role.workload_dev_cloudwatch_agent_check_lambda.id
  policy = data.aws_iam_policy_document.cloudwatch_agent_check_lambda.json
}

resource "aws_iam_role_policy" "workload_prod_cloudwatch_agent_check_lambda" {
  provider = aws.workload_prod

  name   = "cloudwatch-agent-config-rule"
  role   = aws_iam_role.workload_prod_cloudwatch_agent_check_lambda.id
  policy = data.aws_iam_policy_document.cloudwatch_agent_check_lambda.json
}

resource "aws_lambda_function" "workload_dev_cloudwatch_agent_check" {
  provider = aws.workload_dev

  function_name    = "security-baseline-cloudwatch-agent-config-rule"
  role             = aws_iam_role.workload_dev_cloudwatch_agent_check_lambda.arn
  handler          = "lambda_cloudwatch_agent_check.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.cloudwatch_agent_check.output_path
  source_code_hash = data.archive_file.cloudwatch_agent_check.output_base64sha256
  timeout          = 120

  depends_on = [
    aws_iam_role_policy.workload_dev_cloudwatch_agent_check_lambda,
  ]

}

resource "aws_lambda_function" "workload_dev_ssm_managed_check" {
  provider = aws.workload_dev

  function_name    = "security-baseline-ssm-managed-config-rule"
  role             = aws_iam_role.workload_dev_cloudwatch_agent_check_lambda.arn
  handler          = "lambda_ssm_managed_check.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.ssm_managed_check.output_path
  source_code_hash = data.archive_file.ssm_managed_check.output_base64sha256
  timeout          = 120

  depends_on = [
    aws_iam_role_policy.workload_dev_cloudwatch_agent_check_lambda,
  ]

}

resource "aws_lambda_function" "workload_prod_cloudwatch_agent_check" {
  provider = aws.workload_prod

  function_name    = "security-baseline-cloudwatch-agent-config-rule"
  role             = aws_iam_role.workload_prod_cloudwatch_agent_check_lambda.arn
  handler          = "lambda_cloudwatch_agent_check.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.cloudwatch_agent_check.output_path
  source_code_hash = data.archive_file.cloudwatch_agent_check.output_base64sha256
  timeout          = 120

  depends_on = [
    aws_iam_role_policy.workload_prod_cloudwatch_agent_check_lambda,
  ]

}

resource "aws_lambda_function" "workload_prod_ssm_managed_check" {
  provider = aws.workload_prod

  function_name    = "security-baseline-ssm-managed-config-rule"
  role             = aws_iam_role.workload_prod_cloudwatch_agent_check_lambda.arn
  handler          = "lambda_ssm_managed_check.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.ssm_managed_check.output_path
  source_code_hash = data.archive_file.ssm_managed_check.output_base64sha256
  timeout          = 120

  depends_on = [
    aws_iam_role_policy.workload_prod_cloudwatch_agent_check_lambda,
  ]

}

resource "aws_lambda_permission" "workload_dev_allow_config_cloudwatch_agent_check" {
  provider = aws.workload_dev

  statement_id  = "AllowExecutionFromConfig"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.workload_dev_cloudwatch_agent_check.function_name
  principal     = "config.amazonaws.com"
}

resource "aws_lambda_permission" "workload_dev_allow_config_ssm_managed_check" {
  provider = aws.workload_dev

  statement_id  = "AllowExecutionFromConfig"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.workload_dev_ssm_managed_check.function_name
  principal     = "config.amazonaws.com"
}

resource "aws_lambda_permission" "workload_prod_allow_config_cloudwatch_agent_check" {
  provider = aws.workload_prod

  statement_id  = "AllowExecutionFromConfig"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.workload_prod_cloudwatch_agent_check.function_name
  principal     = "config.amazonaws.com"
}

resource "aws_lambda_permission" "workload_prod_allow_config_ssm_managed_check" {
  provider = aws.workload_prod

  statement_id  = "AllowExecutionFromConfig"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.workload_prod_ssm_managed_check.function_name
  principal     = "config.amazonaws.com"
}

resource "aws_config_config_rule" "workload_dev_s3_public_access" {
  provider = aws.workload_dev

  name = "s3-bucket-level-public-access-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_LEVEL_PUBLIC_ACCESS_PROHIBITED"
  }

  depends_on = [
    aws_config_configuration_recorder_status.workload_dev,
  ]
}

resource "aws_config_config_rule" "workload_prod_s3_public_access" {
  provider = aws.workload_prod

  name = "s3-bucket-level-public-access-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_LEVEL_PUBLIC_ACCESS_PROHIBITED"
  }

  depends_on = [
    aws_config_configuration_recorder_status.workload_prod,
  ]
}

resource "aws_config_config_rule" "workload_dev_s3_macie_scan_tag_required" {
  provider = aws.workload_dev

  name = "s3-bucket-macie-scan-tag-required"

  input_parameters = jsonencode({
    tagKey        = var.macie_scan_tag_key
    allowedValues = var.allowed_macie_scan_tag_values
  })

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.workload_dev_s3_macie_scan_tag_check.arn

    source_detail {
      event_source = "aws.config"
      message_type = "ConfigurationItemChangeNotification"
    }

    source_detail {
      event_source = "aws.config"
      message_type = "ScheduledNotification"
    }
  }

  depends_on = [
    aws_config_configuration_recorder_status.workload_dev,
    aws_lambda_permission.workload_dev_allow_config_s3_macie_scan_tag_check,
  ]
}

resource "aws_config_config_rule" "workload_prod_s3_macie_scan_tag_required" {
  provider = aws.workload_prod

  name = "s3-bucket-macie-scan-tag-required"

  input_parameters = jsonencode({
    tagKey        = var.macie_scan_tag_key
    allowedValues = var.allowed_macie_scan_tag_values
  })

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.workload_prod_s3_macie_scan_tag_check.arn

    source_detail {
      event_source = "aws.config"
      message_type = "ConfigurationItemChangeNotification"
    }

    source_detail {
      event_source = "aws.config"
      message_type = "ScheduledNotification"
    }
  }

  depends_on = [
    aws_config_configuration_recorder_status.workload_prod,
    aws_lambda_permission.workload_prod_allow_config_s3_macie_scan_tag_check,
  ]
}

resource "aws_config_config_rule" "workload_dev_ssm_managed_instance" {
  provider = aws.workload_dev

  name = "ec2-instance-managed-by-systems-manager"

  input_parameters = jsonencode({
    tagKey   = var.ssm_managed_tag_key
    tagValue = var.ssm_managed_enabled_value
  })

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.workload_dev_ssm_managed_check.arn

    source_detail {
      event_source = "aws.config"
      message_type = "ConfigurationItemChangeNotification"
    }

    source_detail {
      event_source = "aws.config"
      message_type = "ScheduledNotification"
    }
  }

  depends_on = [
    aws_config_configuration_recorder_status.workload_dev,
    aws_lambda_permission.workload_dev_allow_config_ssm_managed_check,
  ]
}

resource "aws_config_config_rule" "workload_prod_ssm_managed_instance" {
  provider = aws.workload_prod

  name = "ec2-instance-managed-by-systems-manager"

  input_parameters = jsonencode({
    tagKey   = var.ssm_managed_tag_key
    tagValue = var.ssm_managed_enabled_value
  })

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.workload_prod_ssm_managed_check.arn

    source_detail {
      event_source = "aws.config"
      message_type = "ConfigurationItemChangeNotification"
    }

    source_detail {
      event_source = "aws.config"
      message_type = "ScheduledNotification"
    }
  }

  depends_on = [
    aws_config_configuration_recorder_status.workload_prod,
    aws_lambda_permission.workload_prod_allow_config_ssm_managed_check,
  ]
}

resource "aws_config_config_rule" "workload_dev_cloudwatch_agent_association_compliance" {
  provider = aws.workload_dev

  name = "cloudwatch-agent-application-required"

  input_parameters = jsonencode({
    tagKey   = var.cloudwatch_agent_tag_key
    tagValue = var.cloudwatch_agent_enabled_value
  })

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.workload_dev_cloudwatch_agent_check.arn

    source_detail {
      event_source = "aws.config"
      message_type = "ConfigurationItemChangeNotification"
    }

    source_detail {
      event_source = "aws.config"
      message_type = "ScheduledNotification"
    }
  }

  depends_on = [
    aws_config_configuration_recorder_status.workload_dev,
    aws_lambda_permission.workload_dev_allow_config_cloudwatch_agent_check,
  ]
}

resource "aws_config_config_rule" "workload_prod_cloudwatch_agent_association_compliance" {
  provider = aws.workload_prod

  name = "cloudwatch-agent-application-required"

  input_parameters = jsonencode({
    tagKey   = var.cloudwatch_agent_tag_key
    tagValue = var.cloudwatch_agent_enabled_value
  })

  source {
    owner             = "CUSTOM_LAMBDA"
    source_identifier = aws_lambda_function.workload_prod_cloudwatch_agent_check.arn

    source_detail {
      event_source = "aws.config"
      message_type = "ConfigurationItemChangeNotification"
    }

    source_detail {
      event_source = "aws.config"
      message_type = "ScheduledNotification"
    }
  }

  depends_on = [
    aws_config_configuration_recorder_status.workload_prod,
    aws_lambda_permission.workload_prod_allow_config_cloudwatch_agent_check,
  ]
}

resource "aws_config_aggregate_authorization" "workload_dev" {
  provider = aws.workload_dev

  account_id = local.security_account_id
  region     = var.aws_region
}

resource "aws_config_aggregate_authorization" "workload_prod" {
  provider = aws.workload_prod

  account_id = local.security_account_id
  region     = var.aws_region
}

resource "aws_config_configuration_aggregator" "security" {
  provider = aws.security

  name = var.config_aggregator_name

  account_aggregation_source {
    account_ids = [
      local.workload_dev_account_id,
      local.workload_prod_account_id,
    ]
    regions = [var.aws_region]
  }

  depends_on = [
    aws_config_aggregate_authorization.workload_dev,
    aws_config_aggregate_authorization.workload_prod,
  ]

}
