resource "aws_s3_bucket" "frontend" {
    bucket = "${var.project_name}-frontend-2026"
}

resource "aws_s3_bucket_website_configuration" "frontend_config" {
    bucket = aws_s3_bucket.frontend.id
    index_document { suffix = "index.html" } 
    }

resource "aws_s3_bucket" "logs" {
    bucket = "${var.project_name}-logs-2026"
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
    }]
  })
}

resource "aws_iam_instance_profile" "sentinel_profile" {
    name = "${var.project_name}-profile"
    role = aws_iam_role.sentinel-role.name
}