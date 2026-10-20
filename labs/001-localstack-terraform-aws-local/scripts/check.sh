#!/usr/bin/env bash
# Smoke-test every resource created by the lab against the local endpoint.
set -euo pipefail

export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1

bucket=$(terraform output -raw bucket_name)
table=$(terraform output -raw table_name)
queue=$(terraform output -raw queue_url)
instance=$(terraform output -raw instance_id)
parameter=$(terraform output -raw parameter_name)
secret=$(terraform output -raw secret_arn)

echo "== S3"
echo "hello from jaylabs" > /tmp/hello.txt
awslocal s3 cp /tmp/hello.txt "s3://${bucket}/hello.txt"
awslocal s3 ls "s3://${bucket}/"
awslocal s3api get-bucket-versioning --bucket "$bucket"

echo "== DynamoDB"
awslocal dynamodb put-item --table-name "$table" \
  --item '{"id":{"S":"order-001"},"item":{"S":"keyboard"},"qty":{"N":"2"}}'
awslocal dynamodb scan --table-name "$table" --query 'Items' --output json

echo "== SQS"
awslocal sqs send-message --queue-url "$queue" --message-body '{"order_id":"order-001"}'
awslocal sqs receive-message --queue-url "$queue" --query 'Messages[].Body' --output text
awslocal sqs get-queue-attributes --queue-url "$queue" --attribute-names RedrivePolicy

echo "== EC2"
awslocal ec2 describe-instances --instance-ids "$instance" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,InstanceType,PrivateIpAddress]' --output table

echo "== SSM Parameter Store"
awslocal ssm get-parameter --name "$parameter" --query 'Parameter.[Name,Type,Value]' --output table

echo "== Secrets Manager"
awslocal secretsmanager get-secret-value --secret-id "$secret" --query 'SecretString' --output text
