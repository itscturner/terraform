data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "aws_s3_bucket" "storage" {
  bucket = format("storage-%s-%s-an", 
    data.aws_caller_identity.current.account_id, 
    data.aws_region.current.region
    #var.aws_region
  )

  bucket_namespace = "account-regional"

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "regional_bucket_public_block" {
  bucket = aws_s3_bucket.storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
