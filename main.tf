# Configure the AWS provider
provider "aws" {
  region = "us-west-2"
}

# Create an IAM role for the EKS cluster
resource "aws_iam_role" "botgauge" {
  name        = "botgauge"
  description = "EKS cluster role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Create an IAM policy for the EKS cluster
resource "aws_iam_policy" "botgauge" {
  name        = "botgauge"
  description = "EKS cluster policy"

  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "eks:*",
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "botgauge" {
  role       = aws_iam_role.botgauge.name
  policy_arn = aws_iam_policy.botgauge.arn
}

# Create a VPC
resource "aws_vpc" "botgauge" {
  cidr_block = "10.0.0.0/16"
}

# Create public subnets in different AZs
resource "aws_subnet" "botgauge_public" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.botgauge.id
  availability_zone = "us-west-2a"
}

resource "aws_subnet" "botgauge_public_2" {
  cidr_block = "10.0.2.0/24"
  vpc_id     = aws_vpc.botgauge.id
  availability_zone = "us-west-2b"
}

# Create private subnets in different AZs
resource "aws_subnet" "botgauge_private" {
  cidr_block = "10.0.3.0/24"
  vpc_id     = aws_vpc.botgauge.id
  availability_zone = "us-west-2a"
}

resource "aws_subnet" "botgauge_private_2" {
  cidr_block = "10.0.4.0/24"
  vpc_id     = aws_vpc.botgauge.id
  availability_zone = "us-west-2b"
}

# Create an EKS cluster
resource "aws_eks_cluster" "botgauge" {
  name     = "botgauge"
  role_arn = aws_iam_role.botgauge.arn

  vpc_config {
    subnet_ids = [aws_subnet.botgauge_public.id, aws_subnet.botgauge_public_2.id, aws_subnet.botgauge_private.id, aws_subnet.botgauge_private_2.id]
  }
}
