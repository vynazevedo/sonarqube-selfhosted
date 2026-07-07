resource "aws_s3_bucket" "backups" {
  count = var.create_backup_bucket ? 1 : 0

  bucket = local.backup_bucket_name
  tags   = var.tags
}

resource "aws_s3_bucket_public_access_block" "backups" {
  count = var.create_backup_bucket ? 1 : 0

  bucket                  = aws_s3_bucket.backups[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "backups" {
  count = var.create_backup_bucket ? 1 : 0

  bucket = aws_s3_bucket.backups[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "backups" {
  count = var.create_backup_bucket ? 1 : 0

  bucket = aws_s3_bucket.backups[0].id

  rule {
    id     = "expire-old-backups"
    status = "Enabled"

    filter {}

    expiration {
      days = var.backup_retention_days
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
