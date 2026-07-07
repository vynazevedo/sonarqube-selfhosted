data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_subnet" "this" {
  id = var.subnet_id
}

data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-${var.architecture}"
}

locals {
  backup_bucket_name = var.backup_bucket_name != null ? var.backup_bucket_name : "${var.name}-backups-${data.aws_caller_identity.current.account_id}"
}
