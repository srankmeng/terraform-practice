data "aws_efs_file_system" "efs" {
  creation_token  = "tf-test-report"
#   file_system_id = "fs-0d80747f7eb7ab6c2"
}

data "aws_s3_bucket" "datasync_s3" {
  bucket = "async-tf-efs"
}