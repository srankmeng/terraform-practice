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


resource "aws_datasync_task" "datasync_task" {
  name                     = "data-sync-tf-efs"
  source_location_arn      = aws_datasync_location_efs.efs.arn
  destination_location_arn = aws_datasync_location_s3.datasync_s3.arn
}

resource "aws_datasync_location_efs" "efs" {
  efs_file_system_arn = data.aws_efs_file_system.efs.arn

  ec2_config {
    security_group_arns = ["arn:aws:ec2:ap-southeast-1:761152224652:security-group/sg-046b771e18f495278"]
    subnet_arn          = "arn:aws:ec2:ap-southeast-1:761152224652:subnet/subnet-0d7595a1366382629"
  }
}

resource "aws_datasync_location_s3" "datasync_s3" {
  s3_bucket_arn = data.aws_s3_bucket.datasync_s3.arn
  subdirectory  = "/api-test-reports"

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_s3_role.arn
  }
}

resource "aws_iam_role" "datasync_s3_role" {
  name = "datasync_s3_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  inline_policy {
    name = "datasync_s3_policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "s3:GetBucketLocation",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads"
          ]
          Effect = "Allow"
          Resource = "arn:aws:s3:::async-tf-efs"
        },
        {
          Action = [
            "s3:AbortMultipartUpload",
            "s3:DeleteObject",
            "s3:GetObject",
            "s3:ListMultipartUploadParts",
            "s3:PutObjectTagging",
            "s3:GetObjectTagging",
            "s3:PutObject"
          ]
          Effect = "Allow"
          Resource = "arn:aws:s3:::async-tf-efs/*"
        }
      ]
    })
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["datasync.amazonaws.com"]
    }
  }
}
