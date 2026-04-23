resource "tls_private_key" "sentinel_key" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "aws_key_pair" "generated_key" {
    key_name = "${var.project_name}-key"
    public_key = tls_private_key.sentinel_key.public_key_openssh
}

data "aws_ami" "latest_amazon_linux" {
    most_recent = true
    owners = ["amazon"]

    filter {
        name = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}


resource "aws_instance" "sentinel_server" {
    ami = data.aws_ami.latest_amazon_linux.id
    instance_type = "t2.micro"
    vpc_security_group_ids = var.vpc_sg_id
    subnet_id = var.subnet_id
    iam_instance_profile = var.iam_instance_profile
    key_name = aws_key_pair.generated_key.key_name
    user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3 git
              # Pin urllib3 to an older version to fix the OpenSSL error
              pip3 install "urllib3<2" boto3 requests
              pip3 install "urllib3<2" boto3 requests python-dotenv
              echo "Sentinel Engine Prepared" > /home/ec2-user/status.txt
              chown ec2-user:ec2-user /home/ec2-user/status.txt
            EOF
    tags = {
        Name = "${var.project_name}-server"
    }
}

resource "local_file" "private_key" {
    content = tls_private_key.sentinel_key.private_key_pem
    filename = "${path.module}/../../${var.project_name}.pem"
    file_permission = "0400"
}

data "archive_file" "ec2_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/python/EC2_SCRIPT.py"
  output_path = "${path.module}/python/EC2_SCRIPT.zip"
}

data "archive_file" "s3_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/python/S3_SCRIPT.py"
  output_path = "${path.module}/python/S3_SCRIPT.zip"
}


resource "aws_lambda_function" "ec2_lambda" {
    filename = data.archive_file.ec2_lambda_zip.output_path
    function_name = "EC2_Audit"
    role = aws_iam_role.EC2_Lambda_Role.arn
    timeout = 30
    handler = "EC2_SCRIPT.lambda_handler"
    runtime = "python3.12"

    environment {
      variables = {
        APP_REGION = var.region
        TOPIC_ARN_2 = var.topicarn2
      }
    }
}

resource "aws_iam_policy" "EC2_Lambda_Policy" {
    name = "${var.ec2_lambda}-policy"
    policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["sns:Publish"]
        Effect   = "Allow"
        Resource = [var.topicarn2] 
      },
      {
        Action   = ["ec2:DescribeSecurityGroups"]
        Effect   = "Allow"
        Resource = "*" 
      },
      {
        Action   = ["ec2:RevokeSecurityGroupIngress", "ec2:RevokeSecurityGroupEgress"]
        Effect   = "Allow"
        Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "EC2_Lambda_Policy_Attachment" {
    role       = aws_iam_role.EC2_Lambda_Role.name
    policy_arn = aws_iam_policy.EC2_Lambda_Policy.arn
}


resource "aws_iam_role" "EC2_Lambda_Role" {
    name = "${var.ec2_lambda}-role"
    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com"}
    }]
    })
}

resource "aws_lambda_function" "s3_lambda" {
    filename = data.archive_file.s3_lambda_zip.output_path
    function_name = "S3_Audit"
    role = aws_iam_role.S3_Lambda_Role.arn
    timeout = 30
    handler = "S3_SCRIPT.lambda_handler"
    runtime = "python3.12"

    environment {
      variables = {
        APP_REGION = var.region
        TOPIC_ARN = var.topicarn
      }
    }
}

resource "aws_iam_policy" "S3_Lambda_Policy" {
    name = "${var.s3_lambda}-policy"
    policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["sns:Publish"]
        Effect   = "Allow"
        Resource = [var.topicarn] 
      },
      {
        Action   = ["s3:ListAllMyBuckets"]
        Effect   = "Allow"
        Resource = "*" 
      },
      {
        Action   = ["s3:GetBucketPublicAccessBlock", "s3:PutBucketPublicAccessBlock"]
        Effect   = "Allow"
        Resource = "*" 
      }]
  })
}

resource "aws_iam_role_policy_attachment" "S3_Lambda_Policy_Attachment" {
    role       = aws_iam_role.S3_Lambda_Role.name
    policy_arn = aws_iam_policy.S3_Lambda_Policy.arn
}


resource "aws_iam_role" "S3_Lambda_Role" {
    name = "${var.s3_lambda}-role"
    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com"}
    }]
    })
}

resource "aws_cloudwatch_event_rule" "daily_scan" {
    name = "daily_s3_ec2_scan"
    description = "Runs S3 and EC2 audit once per day"
    schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "trigger_ec2_audit" {
    rule = aws_cloudwatch_event_rule.daily_scan.name
    target_id = "EC2AuditLambda"
    arn = aws_lambda_function.ec2_lambda.arn
}

resource "aws_cloudwatch_event_target" "trigger_s3_audit" {
    rule = aws_cloudwatch_event_rule.daily_scan.name
    target_id = "S3AuditLambda"
    arn = aws_lambda_function.s3_lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_ec2" {
    statement_id = "AllowCloudwatchForEC2"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.ec2_lambda.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.daily_scan.arn
}

resource "aws_lambda_permission" "allow_cloudwatch_s3" {
    statement_id = "AllowCloudwatchForS3"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.s3_lambda.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.daily_scan.arn
}

data "archive_file" "sentinel_lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/python/SENTINEL_SCRIPT.py"
  output_path = "${path.module}/python/SENTINEL_SCRIPT.zip"
}

resource "aws_lambda_function" "sentinel_lambda" {
    filename = data.archive_file.sentinel_lambda_zip.output_path
    function_name = "Sentinel"
    role = aws_iam_role.Sentinel_Lambda_Role.arn
    timeout = 30
    handler = "SENTINEL_SCRIPT.lambda_handler"
    runtime = "python3.12"

    environment {
      variables = {
        APP_REGION = var.region
        TOPIC_ARN_2 = var.topicarn3
        INPUT_BUCKET = var.results_bucket_name 
        REPORTS_BUCKET = var.reports_bucket_name 
      }
    }
}

resource "aws_iam_policy" "Sentinel_Lambda_Policy" {
    name = "${var.sentinel_lambda}-policy"
    policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["sns:Publish"]
        Effect   = "Allow"
        Resource = [var.topicarn3] 
      },
      {
        Action   = ["s3:ListBucket"]
        Effect   = "Allow"
        Resource = [var.results_bucket_arn,
        var.reports_bucket_arn]
      },
      {
        Action   = ["s3:GetObject", "s3:PutObject"]
        Effect   = "Allow"
        Resource = ["${var.results_bucket_arn}/*",
          "${var.reports_bucket_arn}/*"]
      },
      {
        Action = ["s3:PutObject"]
        Effect = "Allow"
        Resource = ["${var.reports_bucket_arn}/*"]
      },
      {
        Action   = ["bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
        ]
        Effect   = "Allow"
        Resource = "*" 
    }]
  })
}

resource "aws_iam_role_policy_attachment" "Sentinel_Lambda_Policy_Attachment" {
    role       = aws_iam_role.Sentinel_Lambda_Role.name
    policy_arn = aws_iam_policy.Sentinel_Lambda_Policy.arn
}


resource "aws_iam_role" "Sentinel_Lambda_Role" {
    name = "${var.sentinel_lambda}-role"
    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com"}
    }]
    })
}

resource "aws_lambda_permission" "allow_s3_to_call_sentinel" {
  statement_id  = "AllowS3InvokeSentinel"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sentinel_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.results_bucket_arn
}

resource "aws_s3_bucket_notification" "sentinel_s3_trigger" {
  bucket = var.results_bucket_name 
  lambda_function {
    lambda_function_arn = aws_lambda_function.sentinel_lambda.arn
    events = ["s3:ObjectCreated:*"]
    filter_prefix = "AWSLogs/"
  }
  depends_on = [aws_lambda_permission.allow_s3_to_call_sentinel]
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.Sentinel_Lambda_Role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}