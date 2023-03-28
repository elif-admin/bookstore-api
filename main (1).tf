terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
    github = {
      source = "integrations/github"
      version = "~> 5.0"
    }
  }
}


provider "github" {
 token = "xxxxxxxxxxxxxxxxxxxxx"
}

provider "aws" {
  region = "us-east-1"
 
}
resource "aws_instance" "tf-docker-ec2" {
  ami = "ami-00c39f71452c08778"
  instance_type = "t2.micro"
  key_name = "first-key"
  vpc_security_group_ids = [aws_security_group.tf-docker-sec-gr.id]
  tags = {
    Name = "Web server of Bookstore"
  }
  user_data = <<-EOF
          #! /bin/bash
          yum update -y
          yum install docker -y
          systemctl start docker
          systemctl enable docker
          usermod -a -G docker ec2-user
          newgrp docker
          curl -SL https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
          chmod +x /usr/local/bin/docker-compose
          mkdir -p /home/ec2-user/bookstore-api
          TOKEN="xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
          FOLDER="https://$TOKEN@raw.githubusercontent.com/elif-admin/bookstore-api/main/"
          curl -s --create-dirs -o "/home/ec2-user/bookstore-api/app.py" -L "$FOLDER"bookstore-api.py
          curl -s --create-dirs -o "/home/ec2-user/bookstore-api/requirements.txt" -L "$FOLDER"requirements.txt
          curl -s --create-dirs -o "/home/ec2-user/bookstore-api/Dockerfile" -L "$FOLDER"Dockerfile
          curl -s --create-dirs -o "/home/ec2-user/bookstore-api/docker-compose.yml" -L "$FOLDER"docker-compose.yml
          cd /home/ec2-user/bookstore-api
          docker build -t elifadmin/bookstoreapi:latest .
          docker-compose up -d
          EOF

  depends_on = [github_repository.myrepo, github_repository_file.app-files]
}

resource "aws_security_group" "tf-docker-sec-gr" {
  name = "docker-sec-gr-proje203"
  tags = {
    Name = "docker-sec-gr-proje203"
  }

  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


output "website" {
  value = "http://${aws_instance.tf-docker-ec2.public_ip}"
}








