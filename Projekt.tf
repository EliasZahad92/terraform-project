terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1" #Frankfurt
}
#Sicherheitsgruppe/Firewall
resource "aws_security_group" "my_security" {
  name = "my_sec_group"

  #SSH-Zugriff
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["109.43.177.124/32"]
  }
  #HTTP-Zugriff
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  #Ausgehend
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
#S3 bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-csv-data-bucket-123456789"
}
#Daten-Zuweisung
resource "aws_s3_object" "data_file" {
  bucket = aws_s3_bucket.my_bucket.bucket
  key    = "data/monthly_csv.csv"
  source = "${path.module}/monthly_csv.csv"
  acl    = "private"
}

#Info nach apply
output "instance_ip" {
  value = aws_instance.my_instance.public_ip
}
#IAM
resource "aws_iam_role" "ec2_s3_role" {
  name = "ec2-s3-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [ 
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "ec2_s3_policy" {
  name = "ec2-s3-policy"
  role = aws_iam_role.ec2_s3_role.name

  policy = jsonencode({
    Statement = [
      {
        "Effect" = "Allow"
        "Action" = "s3:GetObject"
        "Resource" = "arn:aws:s3:::my-csv-data-bucket-123456789/*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_s3_profile" {
  name = "ec2-s3-instance-profile"
  role = aws_iam_role.ec2_s3_role.name
}
# EC2 Instanz
resource "aws_instance" "my_instance" {
  ami = "ami-0aa78f446b4499266"
  instance_type = "t3.micro"
  key_name = "ec2-s3"
  iam_instance_profile = aws_iam_instance_profile.ec2_s3_profile.name
  security_groups = [aws_security_group.my_security.name]

  #Skript ausführen
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install python3
              pip install boto3 pandas matplotlib

              aws s3 cp s3://my-csv-data-bucket-123456789/data/monthly_csv.csv /home/ec2-user/monthly_csv.csv

              echo "${file("skript.py")}" > /home/ec2-user/skript.py

              python3 /home/ec2-user/skript.py
              EOF

  tags = {
    Name = "Data-Visualization-Instance"
  }
}