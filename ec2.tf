resource "aws_instance" "DBServer" {
    ami = "ami-0ea87431b78a82070"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.PublicSubnet.id
    vpc_security_group_ids = [aws_security_group.WebTraffic.id]
    tags = {
        Name = "Sentinel-DB-Server"
    }
}
variable "ports" {
    type = list(number)
    default = [80,443,22]
}
output "DB_Private_IP" {
    value = aws_instance.DBServer.private_ip
}
resource "aws_instance" "WebServer" {
    ami = "ami-0ea87431b78a82070"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.PublicSubnet.id
    vpc_security_group_ids = [aws_security_group.WebTraffic.id]
    associate_public_ip_address = true
    user_data = <<-EOF
        #!/bin/bash
        sudo yum update
        sudo yum install -y httpd
        sudo systemctl start httpd
        sudo systemctl enable httpd
        echo "<h1>Hello from Terraform</h1>" | sudo tee /var/www/html/index.html
        EOF
    tags = {
        Name = "Sentinel-Web-Server"
    }
}
resource "aws_eip" "ElasticIP" {
    instance = aws_instance.WebServer.id
}

resource "aws_security_group" "WebTraffic" {
    name = "AllowWebTraffic"
    vpc_id = aws_vpc.TerraformVPC.id
    dynamic "ingress" {
        iterator = port
        for_each = var.ports
        content {
        from_port = port.value
        to_port = port.value
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        }
    }
    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
}
