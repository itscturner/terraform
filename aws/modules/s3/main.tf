#resource "aws_s3_bucket" "storage" {
#  bucket = var.bucket_name
#}

#resource "aws_s3_bucket_versioning" "storage" {
#  bucket = aws_s3_bucket.storage.id

#  versioning_configuration {
#    status = "Enabled"
#  }
#}

#resource "aws_s3_bucket_public_access_block" "storage" {
#  bucket = aws_s3_bucket.storage.id

#  block_public_acls       = true
#  block_public_policy     = true
#  ignore_public_acls      = true
#  restrict_public_buckets = true
#}

##########

# Fetch current AWS account identity and region dynamically
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Create the S3 Bucket inside the Account-Regional Namespace
resource "aws_s3_bucket" "storage" {
  # Naming MUST include your account ID, region, and end with the "-an" suffix
  bucket = format("storage-%s-%s-an", 
    data.aws_caller_identity.current.account_id, 
    data.aws_region.current.region
    #var.aws_region
  )

  # Explicitly opt into the account-regional namespace scope
  bucket_namespace = "account-regional"

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# Explicitly Block All Public Access to the Regional Bucket
resource "aws_s3_bucket_public_access_block" "regional_bucket_public_block" {
  bucket = aws_s3_bucket.storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


