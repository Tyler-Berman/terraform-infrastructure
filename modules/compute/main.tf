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

resource "aws_lambda_function" "ec2_lambda" {
    filename = data.archive_file.ec2_lambda_zip.output_path
    function_name = "EC2_Audit"
    role = aws_iam_role.EC2_Lambda_Role.arn
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

