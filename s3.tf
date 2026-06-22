# ---------------------------------------------------------------------------
# Pipeline artifacts bucket (CodePipeline's internal working storage)
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "pipeline_artifacts" {
  bucket        = var.pipeline_artifacts_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "pipeline_artifacts" {
  bucket                  = aws_s3_bucket.pipeline_artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------
# DEV bucket — first landing spot for every commit, private (review only)
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "dev" {
  bucket        = var.dev_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "dev" {
  bucket                  = aws_s3_bucket.dev.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------
# STG bucket — promoted from dev after approval #1, private (review only)
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "stg" {
  bucket        = var.stg_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "stg" {
  bucket                  = aws_s3_bucket.stg.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------------------------------------------------------------------------
# PROD bucket — promoted from stg after approval #2, public static website
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "prod" {
  bucket        = var.prod_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "prod_website" {
  bucket = aws_s3_bucket.prod.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "prod" {
  bucket = aws_s3_bucket.prod.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "prod_policy" {
  depends_on = [aws_s3_bucket_public_access_block.prod]
  bucket     = aws_s3_bucket.prod.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.prod.arn}/*"
      }
    ]
  })
}
