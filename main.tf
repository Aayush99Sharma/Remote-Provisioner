provider "aws" {
  region = "us-west-2" # Replace with your preferred AWS region
}

# Variables
variable "instance_type" {
  default = "t3.micro"
}

variable "ami_id" {
  # Replace with the latest Ubuntu AMI for your region
  default = "ami-0c779fe4d45aced3d"
}

variable "key_pair_name" {
  default = "fb-key-pair" # Replace with your key pair
}

# VPC
resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "provision-vpc"
  }
}

# Subnet
resource "aws_subnet" "example" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "provision-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id
  tags = {
    Name = "provision-igw"
  }
}

# Route Table
resource "aws_route_table" "example" {
  vpc_id = aws_vpc.example.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.example.id
  }
  tags = {
    Name = "provision-route-table"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "example" {
  subnet_id      = aws_subnet.example.id
  route_table_id = aws_route_table.example.id
}

# Security Group
resource "aws_security_group" "example" {
  vpc_id = aws_vpc.example.id
  name   = "provision-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "provision-sg"
  }
}

# EC2 Instance
resource "aws_instance" "example" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair_name
  subnet_id     = aws_subnet.example.id
   vpc_security_group_ids = [
    aws_security_group.example.id
  ]

  tags = {
    Name = "provision-vm"
  }

   connection {
    type = "ssh"
    user = "ubuntu"
    private_key = "${file("/home/ubuntu/fb-key-pair.pem")}"
    host = "${aws_instance.example.public_ip}"
    port = 22
  }

  provisioner "file" {
    source  = "/home/ubuntu/script.sh"
    destination = "/home/ubuntu/script.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/script.sh",
      "/home/ubuntu/script.sh"
    ]
  }
}

# Elastic IP
resource "aws_eip" "example" {
  instance = aws_instance.example.id
  tags = {
    Name = "provision-eip"
  }
}
