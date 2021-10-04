terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_security_group" "allow_nomad" {
  name        = "allow_nomad"
  description = "Allow Nomad api traffic"

  ingress = [
    {
      description      = "Nomad API Traffic"
      from_port        = 4646
      to_port          = 4646
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      prefix_list_ids  = null
      security_groups  = null
      self             = null
      ipv6_cidr_blocks = null
    },

        {
      description      = "Test Traffic"
      from_port        = 5000
      to_port          = 5000
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      prefix_list_ids  = null
      security_groups  = null
      self             = null
      ipv6_cidr_blocks = null
    }
  ]

  egress = [
    {
      description      = "Nomad Egress"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = null
      security_groups  = null
      self             = null
      ipv6_cidr_blocks = null
    }
  ]
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ssm_profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_iam_role" "ssm_role" {
  name = "ssm_role"

  assume_role_policy  = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", ]
}

resource "aws_instance" "density-nomad" {
    ami = "ami-0747bdcabd34c712a"
    instance_type = "t2.micro"
    associate_public_ip_address = "true"
    iam_instance_profile = "${aws_iam_instance_profile.ssm_profile.name}"
    security_groups = ["${aws_security_group.allow_nomad.name}"]

    tags = {
    Name = "nomad cluster"
  } 
}