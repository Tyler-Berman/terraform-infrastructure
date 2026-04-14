resource "aws_internet_gateway" "Sentinel_IGW" {
  vpc_id = aws_vpc.TerraformVPC.id
  tags   = { Name = "Sentinel-IGW" }
}

resource "aws_subnet" "PublicSubnet" {
  vpc_id = aws_vpc.TerraformVPC.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = { 
    Name = "Sentinel-Public-Subnet" }
}

resource "aws_route_table" "PublicRT" {
  vpc_id = aws_vpc.TerraformVPC.id
  route {
    cidr_block = "0.0.0.0/0" 
    gateway_id = aws_internet_gateway.Sentinel_IGW.id 
  }
  tags = { 
    Name = "Sentinel-Route-Table" }
}
resource "aws_route_table_association" "PublicAssoc" {
  subnet_id = aws_subnet.PublicSubnet.id
  route_table_id = aws_route_table.PublicRT.id
}