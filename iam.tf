resource "aws_iam_user" "IAMUser" {
    name = "Tyler"
}

resource "aws_iam_policy" "NewPolicy" {
    name = "SentinelUserTerraformPolicy"
    policy = <<EOF
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "VisualEditor0",
			"Effect": "Allow",
			"Action": [
				"s3:GetObject",
				"s3:GetBucketWebsite",
				"s3:ListBucket"
			],
			"Resource": "arn:aws:s3:::ai-sentinel-security-results-2026-east-1"
		}
	]
}
EOF

}

resource "aws_iam_policy_attachment" "policyadd" {
    name = "attachment"
    users = [aws_iam_user.IAMUser.name]
    policy_arn = aws_iam_policy.NewPolicy.arn
}