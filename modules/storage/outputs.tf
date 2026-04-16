output "instance_profile_name" {
    value = aws_iam_instance_profile.sentinel_profile.name
}

output "website_url" {
    value = aws_s3_bucket_website_configuration.frontend_config.website_endpoint
}
