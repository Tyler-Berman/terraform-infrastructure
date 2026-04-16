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
    user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y python3 git
              pip3 install boto3 requests
              echo "Sentinel Engine Prepared" > /home/ec2-user/status.txt
              EOF
    tags = {
        Name = "${var.project_name}-server"
    }
}