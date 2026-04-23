resource "aws_s3_bucket" "frontend" {
    bucket = "${var.project_name}-frontend-2026"
    force_destroy = true
}

resource "aws_s3_bucket_website_configuration" "frontend_config" {
    bucket = aws_s3_bucket.frontend.id
    index_document { suffix = "index.html" } 
    }
resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.frontend.id
  depends_on = [ aws_s3_bucket_public_access_block.frontend ]
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      },
    ]
  })
}

resource "aws_s3_bucket_ownership_controls" "frontend_oc" {
  bucket = aws_s3_bucket.frontend.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket" "logs" {
    bucket = "${var.project_name}-logs-2026"
    force_destroy = true
}

resource "aws_iam_role" "sentinel-role" {
    name = "${var.project_name}-role"

    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "s3_access" {
    name = "${var.project_name}-s3-policy"
    role = aws_iam_role.sentinel-role.id
    policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
      Effect   = "Allow"
      Resource = [
        aws_s3_bucket.logs.arn,
        "${aws_s3_bucket.logs.arn}/*"
      ]
    },
    {
      Action = ["s3:PutObject"]
      Effect = "Allow"
      Resource = [
        aws_s3_bucket.reports.arn,
        "${aws_s3_bucket.reports.arn}/*"
      ]
    }]
  })
}

resource "aws_iam_instance_profile" "sentinel_profile" {
    name = "${var.project_name}-profile"
    role = aws_iam_role.sentinel-role.name
}

resource "aws_s3_bucket" "reports" {
    bucket = "${var.project_name}-reports-2026"
    force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "logs_access" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "reports_access" {
  bucket = aws_s3_bucket.reports.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "allow_cloudtrail_logging" {
  bucket = aws_s3_bucket.logs.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs.arn}/AWSLogs/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      },
      {
        Sid    = "AWSLogDeliveryWrite"
        Effect = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logs.arn}/AWSLogs/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      },
      {
        Sid    = "AWSLogDeliveryCheck"
        Effect = "Allow"
        Principal = { Service = "delivery.logs.amazonaws.com" }
        Action   = ["s3:GetBucketAcl", "s3:ListBucket"]
        Resource = aws_s3_bucket.logs.arn
      }
    ]
  })
}