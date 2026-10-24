# =============================================================
# MODULE: storage
# What it does: Creates a secure S3 bucket
# Security: encrypted, versioned, no public access, access logging
# =============================================================

# The S3 bucket
resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# BLOCK all public access — nobody on the internet can read this
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true   # block public ACLs
  block_public_policy     = true   # block public bucket policies
  ignore_public_acls      = true   # ignore any existing public ACLs
  restrict_public_buckets = true   # only authorized users can access
}

# Enable VERSIONING — keeps old versions of files
# Why? If someone deletes a file by accident, you can restore it
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable ENCRYPTION at rest — data is encrypted when stored
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"   # industry standard encryption
    }
    bucket_key_enabled = true    # reduces encryption costs
  }
}

# S3 bucket for ACCESS LOGS — who accessed what and when
resource "aws_s3_bucket" "logs" {
  bucket = "${var.bucket_name}-logs"

  tags = {
    Name        = "${var.bucket_name}-logs"
    Environment = var.environment
    Purpose     = "access-logs"
  }
}

# Block public access on the logs bucket too
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable logging on the main bucket — writes logs to the logs bucket
resource "aws_s3_bucket_logging" "main" {
  bucket        = aws_s3_bucket.main.id
  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3-access-logs/"
}

# Lifecycle rule — automatically delete old files to save cost
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    # Delete old versions after 90 days
    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    # Move old versions to cheaper storage after 30 days
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }
  }
}
