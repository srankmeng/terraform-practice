# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret
data "aws_secretsmanager_secret" "terraform_db" {
  arn = "arn:aws:secretsmanager:ap-southeast-1:761152224652:secret:TERRAFORM_DB-C478rP"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/secretsmanager_secret_version
data "aws_secretsmanager_secret_version" "terraform_db_current" {
  secret_id = data.aws_secretsmanager_secret.terraform_db.id
}
