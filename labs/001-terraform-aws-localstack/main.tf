resource "aws_s3_bucket" "this" {
  bucket = "${var.project}-bucket"

  # Versioned bucket: let destroy delete all object versions first
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "orders" {
  name         = "${var.project}-orders"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_sqs_queue" "orders_dlq" {
  name = "${var.project}-orders-dlq"
}

resource "aws_sqs_queue" "orders" {
  name = "${var.project}-orders"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.orders_dlq.arn
    maxReceiveCount     = 3
  })
}
