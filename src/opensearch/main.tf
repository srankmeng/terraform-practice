terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = var.region
  profile = var.profile
}

locals {
  domain_name = "tf-domain"
  bucket_name = "tf-snapshot-opensearch"
  account_id = data.aws_caller_identity.current.account_id
}


resource "aws_opensearch_domain" "opensearch" {
  domain_name    = local.domain_name
  engine_version = "OpenSearch_2.5"

  cluster_config {
    instance_type = "t3.small.search"
    instance_count = 1
    zone_awareness_enabled = false
    # zone_awareness_config {
    #   availability_zone_count = 1
    # }
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp2"
    volume_size = 10
  }

  advanced_security_options {
    enabled                        = true
    anonymous_auth_enabled         = false
    # internal_user_database_enabled = true
    # master_user_options {
    #   master_user_name     = "elastic"
    #   master_user_password = "P@ssw0rd"
    # }

    internal_user_database_enabled = false
    master_user_options {
      master_user_arn = aws_iam_user.user.arn
    }
  }

  encrypt_at_rest {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https       = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  node_to_node_encryption {
    enabled = true
  }

  # auto_tune_options {
  #   desired_state = "ENABLED"
  #   rollback_on_disable = "NO_ROLLBACK"
  #   maintenance_schedule {
  #     start_at = "2023-03-20T15:00:00Z"
  #     duration {
  #       value  = 1
  #       unit  = "HOURS"
  #     }
  #     cron_expression_for_recurrence = "cron(0 15 ? * 1 *)"
  #   }
  # }

  access_policies = data.aws_iam_policy_document.policy.json

  # vpc_options {
  #   subnet_ids = [
  #     data.aws_subnet_ids.example.ids[0],
  #     data.aws_subnet_ids.example.ids[1],
  #   ]

  #   security_group_ids = [aws_security_group.example.id]
  # }
 depends_on = [
    aws_iam_user_policy.user_policy
  ]
}

data "aws_iam_policy_document" "policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["es:*"]
    resources = ["arn:aws:es:${var.region}:${local.account_id}:domain/${local.domain_name}/*"]
  }
}

// snapshot s3 bucket
resource "aws_s3_bucket" "snapshot_bucket" {
  bucket = local.bucket_name
}

// snapshot role & policy
data "aws_iam_policy_document" "snapshot_policy_doc" {
  statement {
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${local.bucket_name}"
    ]
  }
  
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      "arn:aws:s3:::${local.bucket_name}/*"
    ]
  }

  depends_on = [aws_s3_bucket.snapshot_bucket]
}

resource "aws_iam_policy" "snapshot_policy" {
  name        = "tf-role-opensearch-snapshot"
  description = "terraform opensearch snapshot for access s3"
  policy = data.aws_iam_policy_document.snapshot_policy_doc.json
}

resource "aws_iam_role" "snapshot_role" {
  name = "tf-snapshot_role"
  description = "terraform opensearch snapshot for access s3"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "es.amazonaws.com"
        }
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:es:${var.region}:${local.account_id}:domain/${local.domain_name}"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "snapshot_role_policy" {
  role       = aws_iam_role.snapshot_role.name
  policy_arn = aws_iam_policy.snapshot_policy.arn
}

// snapshot iam user
resource "aws_iam_user" "user" {
  name = "tf-opensearch-snapshot"
  force_destroy = true
}

# resource "aws_iam_access_key" "user_key" {
#   user = aws_iam_user.user.name
# }

data "aws_iam_policy_document" "user_policy_doc" {
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${local.account_id}:role/${aws_iam_role.snapshot_role.name}"]
  }

  statement {
    effect    = "Allow"
    actions   = ["es:ESHttpPut"]
    resources = ["arn:aws:es:${var.region}:${local.account_id}:domain/${local.domain_name}/*"]
  }
}

resource "aws_iam_user_policy" "user_policy" {
  name   = "tf-user-opensearch-snapshot"
  user   = aws_iam_user.user.name
  policy = data.aws_iam_policy_document.user_policy_doc.json
}
