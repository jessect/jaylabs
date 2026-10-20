resource "aws_ssm_parameter" "app_env" {
  name  = "/jaylabs/lab001/app_env"
  type  = "String"
  value = "dev"
}

resource "random_password" "db" {
  length  = 24
  special = false
}

resource "aws_secretsmanager_secret" "db" {
  name = "${var.project}/db-credentials"

  # Lab only: delete immediately on destroy so the next apply can reuse the name.
  # Real environments should keep the default 30-day recovery window.
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = "app"
    password = random_password.db.result
  })
}
