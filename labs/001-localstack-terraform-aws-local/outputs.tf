output "bucket_name" {
  value = aws_s3_bucket.this.bucket
}

output "table_name" {
  value = aws_dynamodb_table.orders.name
}

output "queue_url" {
  value = aws_sqs_queue.orders.url
}

output "instance_id" {
  value = aws_instance.app.id
}

output "ami_id" {
  value = data.aws_ami.al2023.id
}

output "parameter_name" {
  value = aws_ssm_parameter.app_env.name
}

output "secret_arn" {
  value = aws_secretsmanager_secret.db.arn
}
