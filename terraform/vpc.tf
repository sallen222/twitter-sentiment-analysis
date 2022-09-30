resource "aws_vpc" "twitter-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "twitter-vpc"
  }
}

resource "aws_subnet" "subnet-1" {
  cidr_block        = cidrsubnet(aws_vpc.twitter-vpc.cidr_block, 3, 1)
  vpc_id            = aws_vpc.twitter-vpc.id
  availability_zone = "us-east-1a"
}

resource "aws_security_group" "twitter-sg" {
  name   = "allow-all-sg"
  vpc_id = aws_vpc.twitter-vpc.id
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  } // Terraform removes the default rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_internet_gateway" "twitter-vpc-gw" {
  vpc_id = aws_vpc.twitter-vpc.id
  tags = {
    Name = "twitter-vpc-gw"
  }
}

resource "aws_route_table" "route-table-twitter-vpc" {
  vpc_id = aws_vpc.twitter-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.twitter-vpc-gw.id
  }
  tags = {
    Name = "twitter-vpc-route-table"
  }
}

resource "aws_route_table_association" "subnet-association" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.route-table-twitter-vpc.id
}

resource "aws_eip" "twitter-eip" {
  instance = aws_instance.listener-instance.id
  vpc      = true
}