#Header
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = "xxxxxx" #Put your credentials
  secret_key = "xxxxxx" #Put your credentials
}

# Create a VPC
resource "aws_vpc" "VPC_Default" {
  cidr_block = "10.0.0.0/16"
}

# Create Subnet
resource "aws_subnet" "Subnet1" {
  vpc_id     = aws_vpc.VPC_Default.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "Subnet1"
  }
}

#Create Security Group
resource "aws_security_group" "allow_sql" {
  name        = "allow_sql"
  description = "Allow SQL inbound traffic"
  vpc_id      = aws_vpc.VPC_Default.id

  ingress {
    description = "MYSQL from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.VPC_Default.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_db"
  }
}

#Select the AIM
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}


# Launch Instance
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_sql.id]
  subnet_id = aws_subnet.Subnet1.id
  associate_public_ip_address = true
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y mariadb-server
              systemctl enable mariadb
              systemctl start mariadb
              EOF
}
