output "instance_profile_name" {
    value = aws_iam_instance_profile.sentinel_profile.name
}

output "website_url" {
    value = aws_s3_bucket_website_configuration.frontend_config.website_endpoint
}

output "results_bucket_arn" {
    value = aws_s3_bucket.logs.arn
}
output "results_bucket_name" {
    value = aws_s3_bucket.logs.id
}

output "reports_bucket_arn" {
    value = aws_s3_bucket.reports.arn
}

output "reports_bucket_name" {
    value = aws_s3_bucket.reports.id
}