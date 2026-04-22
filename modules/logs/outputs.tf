output "s3_sentinel_policy" {
    value = aws_iam_role_policy.s3_access_ct.policy
}