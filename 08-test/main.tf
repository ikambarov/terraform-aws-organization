data "aws_partition" "current" {
  provider = aws.identity_center
}

data "aws_ssoadmin_instances" "current" {
  provider = aws.identity_center
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = [var.amazon_linux_2023_ami_owner]

  filter {
    name   = "name"
    values = [var.amazon_linux_2023_ami_name_pattern]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  identity_store_id = one(data.aws_ssoadmin_instances.current.identity_store_ids)

  workload_dev_account_id       = var.workload_dev_account_id
  workload_dev_account_role_arn = "arn:${data.aws_partition.current.partition}:iam::${local.workload_dev_account_id}:role/${var.member_account_role_name}"

  public_access_block_disabled_bucket_name = coalesce(
    var.public_access_block_disabled_bucket_name,
    "security-baseline-public-block-test-${local.workload_dev_account_id}-${var.aws_region}"
  )

  macie_scan_enabled_bucket_name = coalesce(
    var.macie_scan_enabled_bucket_name,
    "security-baseline-macie-${local.workload_dev_account_id}-${var.aws_region}"
  )

  common_tags = merge(var.tags, {
    ManagedBy = "Terraform"
    Purpose   = "security-baseline-test"
  })

  public_access_block_disabled_bucket_tags = merge(local.common_tags, {
    Name      = "${var.name_prefix}-public-access-block-disabled"
    MacieScan = "disabled"
  })

  macie_scan_enabled_bucket_tags = merge(local.common_tags, {
    Name      = "${var.name_prefix}-macie-scan-enabled"
    MacieScan = "enabled"
  })

  cloudwatch_agent_missing_instance_tags = merge(local.common_tags, {
    Name            = "${var.name_prefix}-cloudwatch-agent-missing"
    CloudWatchAgent = "enabled"
    SSMManaged      = "disabled"
    Backup          = "daily"
  })

  cloudwatch_agent_installed_instance_tags = merge(local.common_tags, {
    Name            = "${var.name_prefix}-cloudwatch-agent-installed"
    CloudWatchAgent = "enabled"
    SSMManaged      = "disabled"
    Backup          = "daily"
  })

  ssm_unmanaged_instance_tags = merge(local.common_tags, {
    Name            = "${var.name_prefix}-ssm-unmanaged"
    CloudWatchAgent = "disabled"
    SSMManaged      = "enabled"
    Backup          = "disabled"
  })

  ssm_managed_instance_tags = merge(local.common_tags, {
    Name            = "${var.name_prefix}-ssm-managed"
    CloudWatchAgent = "disabled"
    SSMManaged      = "enabled"
    Backup          = "disabled"
  })

  cloudwatch_agent_role_name             = coalesce(var.cloudwatch_agent_role_name, "${var.name_prefix}-cloudwatch-agent-role")
  cloudwatch_agent_instance_profile_name = coalesce(var.cloudwatch_agent_instance_profile_name, "${var.name_prefix}-cloudwatch-agent-profile")
  ssm_instance_role_name                 = coalesce(var.ssm_instance_role_name, "${var.name_prefix}-ssm-instance-role")
  ssm_instance_profile_name              = coalesce(var.ssm_instance_profile_name, "${var.name_prefix}-ssm-instance-profile")
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_identitystore_user" "user1" {
  provider = aws.identity_center

  identity_store_id = local.identity_store_id
  user_name         = var.user1.user_name
  display_name      = var.user1.display_name

  name {
    given_name  = var.user1.given_name
    family_name = var.user1.family_name
  }

  emails {
    value   = var.user1.email
    primary = true
    type    = "work"
  }
}

resource "aws_identitystore_user" "user2" {
  provider = aws.identity_center

  identity_store_id = local.identity_store_id
  user_name         = var.user2.user_name
  display_name      = var.user2.display_name

  name {
    given_name  = var.user2.given_name
    family_name = var.user2.family_name
  }

  emails {
    value   = var.user2.email
    primary = true
    type    = "work"
  }
}

resource "aws_s3_bucket" "public_access_block_disabled" {
  bucket        = local.public_access_block_disabled_bucket_name
  force_destroy = var.force_destroy_test_buckets
  tags          = local.public_access_block_disabled_bucket_tags
}

resource "aws_s3_bucket_public_access_block" "public_access_block_disabled" {
  bucket = aws_s3_bucket.public_access_block_disabled.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_server_side_encryption_configuration" "public_access_block_disabled" {
  bucket = aws_s3_bucket.public_access_block_disabled.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket" "macie_scan_enabled" {
  bucket        = local.macie_scan_enabled_bucket_name
  force_destroy = var.force_destroy_test_buckets
  tags          = local.macie_scan_enabled_bucket_tags
}

resource "aws_s3_bucket_public_access_block" "macie_scan_enabled" {
  bucket = aws_s3_bucket.macie_scan_enabled.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "macie_scan_enabled" {
  bucket = aws_s3_bucket.macie_scan_enabled.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_object" "sample_fake_sensitive_data" {
  bucket       = aws_s3_bucket.macie_scan_enabled.id
  key          = var.sample_sensitive_data_object_key
  content      = var.sample_sensitive_data_content
  content_type = "text/plain"

  tags = {
    Purpose = "security-baseline-test"
  }
}

resource "aws_security_group" "egress_only" {
  name        = "${var.name_prefix}-egress-only"
  description = "Egress-only security group for security baseline EC2 test instances."
  vpc_id      = data.aws_vpc.default.id

  egress {
    description = "Allow outbound traffic for package installation and AWS service access."
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${var.name_prefix}-egress-only"
  })
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudwatch_agent" {
  name               = local.cloudwatch_agent_role_name
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.cloudwatch_agent.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_ssm" {
  role       = aws_iam_role.cloudwatch_agent.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "cloudwatch_agent" {
  name = local.cloudwatch_agent_instance_profile_name
  role = aws_iam_role.cloudwatch_agent.name

  tags = local.common_tags
}

resource "aws_iam_role" "ssm_instance" {
  name               = local.ssm_instance_role_name
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ssm_instance" {
  role       = aws_iam_role.ssm_instance.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_instance" {
  name = local.ssm_instance_profile_name
  role = aws_iam_role.ssm_instance.name

  tags = local.common_tags
}

resource "aws_instance" "cloudwatch_agent_missing" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.egress_only.id]
  associate_public_ip_address = true
  user_data_replace_on_change = true

  user_data = <<-EOT
    #!/bin/bash
    set -eux
    dnf remove -y amazon-cloudwatch-agent || true
    systemctl disable --now amazon-cloudwatch-agent || true
  EOT

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted             = true
    delete_on_termination = true
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
  }

  tags        = local.cloudwatch_agent_missing_instance_tags
  volume_tags = local.cloudwatch_agent_missing_instance_tags
}

resource "aws_instance" "cloudwatch_agent_installed" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.egress_only.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.cloudwatch_agent.name
  user_data_replace_on_change = true

  user_data = <<-EOT
    #!/bin/bash
    set -eux
    dnf install -y amazon-ssm-agent || true
    systemctl enable --now amazon-ssm-agent
    dnf install -y amazon-cloudwatch-agent
    cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'EOF'
    {
      "metrics": {
        "append_dimensions": {
          "InstanceId": "$${aws:InstanceId}"
        },
        "metrics_collected": {
          "mem": {
            "measurement": [
              "mem_used_percent"
            ],
            "metrics_collection_interval": 60
          }
        }
      }
    }
    EOF
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
      -a fetch-config \
      -m ec2 \
      -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
      -s || true
  EOT

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted             = true
    delete_on_termination = true
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
  }

  depends_on = [
    aws_iam_role_policy_attachment.cloudwatch_agent,
    aws_iam_role_policy_attachment.cloudwatch_agent_ssm,
  ]

  tags        = local.cloudwatch_agent_installed_instance_tags
  volume_tags = local.cloudwatch_agent_installed_instance_tags
}

resource "aws_instance" "ssm_unmanaged" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.egress_only.id]
  associate_public_ip_address = true
  user_data_replace_on_change = true

  user_data = <<-EOT
    #!/bin/bash
    set -eux
    systemctl disable --now amazon-ssm-agent || true
    dnf remove -y amazon-ssm-agent || true
  EOT

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted             = true
    delete_on_termination = true
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
  }

  tags        = local.ssm_unmanaged_instance_tags
  volume_tags = local.ssm_unmanaged_instance_tags
}

resource "aws_instance" "ssm_managed" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.egress_only.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ssm_instance.name
  user_data_replace_on_change = true

  user_data = <<-EOT
    #!/bin/bash
    set -eux
    dnf install -y amazon-ssm-agent || true
    systemctl enable --now amazon-ssm-agent
  EOT

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    encrypted             = true
    delete_on_termination = true
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
  }

  depends_on = [
    aws_iam_role_policy_attachment.ssm_instance,
  ]

  tags        = local.ssm_managed_instance_tags
  volume_tags = local.ssm_managed_instance_tags
}
