resource "aws_cloudtrail" "sentinel_cloudtrail" {
    depends_on = [  ]
    name = "${var.project_name}-CT-Logs"
    s3_bucket_name = var.results_bucket_name
    include_global_service_events = true
    enable_logging = false
    is_multi_region_trail = true
    
}

resource "aws_iam_role" "sentinel-role-ct" {
    name = "${var.project_name}-CT-Role"

    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "cloudtrail.amazonaws.com" }
    }]
  })
}
resource "aws_iam_role_policy" "s3_access_ct" {
    name = "${var.project_name}-s3-ct-policy"
    role = aws_iam_role.sentinel-role-ct.id
    policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["s3:PutObject", "s3:GetBucketAcl"]
      Effect   = "Allow"
      Resource = [
        var.results_bucket_arn,
        "${var.results_bucket_arn}/*"
      ]
    }]})
}



