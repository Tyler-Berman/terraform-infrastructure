
resource "aws_vpc" "Sentinel-VPC-Project" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "MyTerraformVPC"
    }
}