# Plain provider block: no endpoints, no fake keys.
# Run with tflocal, which generates localstack_providers_override.tf
# pointing every AWS service at http://localhost:4566.
terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "demo" {
  bucket        = "jaylabs-lab001-tflocal-bucket"
  force_destroy = true
}

resource "aws_ssm_parameter" "demo" {
  name  = "/jaylabs/lab001/tflocal"
  type  = "String"
  value = "deployed with tflocal"
}

output "bucket_name" {
  value = aws_s3_bucket.demo.bucket
}
