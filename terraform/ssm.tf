resource "random_password" "db" {
  length           = 40
  special          = true
  override_special = "-_"
}

resource "aws_ssm_parameter" "db_password" {
  name  = "/${var.name}/db-password"
  type  = "SecureString"
  value = random_password.db.result
  tags  = var.tags
}
