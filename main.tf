# Configure the AWS provider
provider "aws" {
  region = "us-west-2"
}

# Generate a random name
variable "random_name" {
  type = string
}

# Create an IAM role for the EKS cluster
resource "aws_iam_role" "eks_cluster_role" {
  name        = "eks-cluster-role-${var.random_name}"
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
resource "aws_iam_policy" "eks_cluster_policy" {
  name        = "eks-cluster-policy-${var.random_name}"
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
resource "aws_iam_role_policy_attachment" "eks_cluster_role_policy_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = aws_iam_policy.eks_cluster_policy.arn
}

# Create a VPC
resource "aws_vpc" "eks_cluster_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create public subnets in different AZs
resource "aws_subnet" "eks_cluster_public" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.eks_cluster_vpc.id
  availability_zone = "us-west-2a"
  name        = "eks-cluster-public-${var.random_name}"
}

resource "aws_subnet" "eks_cluster_public_2" {
  cidr_block = "10.0.2.0/24"
  vpc_id     = aws_vpc.eks_cluster_vpc.id
  availability_zone = "us-west-2b"
  name        = "eks-cluster-public-2-${var.random_name}"
}

# Create private subnets in different AZs
resource "aws_subnet" "eks_cluster_private" {
  cidr_block = "10.0.3.0/24"
  vpc_id     = aws_vpc.eks_cluster_vpc.id
  availability_zone = "us-west-2a"
  name        = "eks-cluster-private-${var.random_name}"
}

resource "aws_subnet" "eks_cluster_private_2" {
  cidr_block = "10.0.4.0/24"
  vpc_id     = aws_vpc.eks_cluster_vpc.id
  availability_zone = "us-west-2b"
  name        = "eks-cluster-private-2-${var.random_name}"
}

# Create an EKS cluster
resource "aws_eks_cluster" "eks_cluster" {
  name     = "eks-cluster-${var.random_name}"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [aws_subnet.eks_cluster_public.id, aws_subnet.eks_cluster_public_2.id, aws_subnet.eks_cluster_private.id, aws_subnet.eks_cluster_private_2.id]
  }
}