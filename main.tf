#main.tf
terraform {
  ###BEGIN COMMENT OUT SECTION
    backend "s3" {
      key    = "global/tf-aws-bootstrap/terraform.tfstate"
      region = "us-east-2"
      dynamodb_table = "tfstate-locks"
      encrypt = true
      #Add to backend.hcl
      #access_key
      #secret_key
      #bucket
    }
  ###END COMMENT OUT SECTION
    required_providers {
      aws = {
        source = "hashicorp/aws"
      }
    }
}
provider "aws" {
    region = var.aws_region
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key
}

resource "aws_s3_bucket" "tf_state" {
  bucket = "nog-prod-tf-state"
  lifecycle {
    prevent_destroy = true
  }
}
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.tf_state.id
  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true 
}

resource "aws_dynamodb_table" "tfstate-locks" {
  name = "tfstate-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.tf_state.arn
  description = "The ARN of the S3 bucket"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.tfstate-locks.name
  description = "The name of the DynamoDB table"
}