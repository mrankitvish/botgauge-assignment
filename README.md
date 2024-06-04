# Botgauge App

This repository contains the necessary files and instructions to create, build, and deploy the Botgauge application on an EKS cluster using Terraform and GitHub Actions.

## Steps to Setup and Deploy

### Step 1: Create an HTTP Server in Golang

Create a simple HTTP server in Go that responds with "Hello from Botgauge" at the `/hello` endpoint.

```go
package main

import (
    "fmt"
    "net/http"
)

func helloHandler(w http.ResponseWriter, r *http.Request) {
    if r.URL.Path != "/hello" {
        http.NotFound(w, r)
        return
    }
    fmt.Fprintf(w, "Hello from Botgauge")
}

func main() {
    http.HandleFunc("/hello", helloHandler)
    fmt.Println("Starting server on :8080")
    if err := http.ListenAndServe(":8080", nil); err != nil {
        fmt.Println("Error starting server:", err)
    }
}
```
### Step 2: Create Dockerfile for the Server
Create a Dockerfile to containerize the Go application.

```dockerfile
Copy code
FROM golang:alpine

WORKDIR /app

COPY main.go /app/

RUN go build -o main main.go

EXPOSE 8080

CMD ["./main"]
```
### Step 3: Create Terraform Configuration for EKS Cluster
Create a main.tf file to provision an automated EKS Cluster on AWS.

``` json
# Configure the AWS provider
provider "aws" {
  region = "us-west-2"
}

# Create an IAM role for the EKS cluster
resource "aws_iam_role" "botgauge-app" {
  name        = "botgauge-app"
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
resource "aws_iam_policy" "botgauge-app" {
  name        = "botgauge-app"
  description = "EKS cluster policy"

  policy = <<EOF
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
resource "aws_iam_role_policy_attachment" "botgauge-app" {
  role       = aws_iam_role.botgauge-app.name
  policy_arn = aws_iam_policy.botgauge-app.arn
}

# Create a VPC
resource "aws_vpc" "botgauge-app" {
  cidr_block = "10.0.0.0/16"
}

# Create public subnets in different AZs
resource "aws_subnet" "botgauge-app-public" {
  cidr_block         = "10.0.1.0/24"
  vpc_id             = aws_vpc.botgauge-app.id
  availability_zone  = "us-west-2a"
}

resource "aws_subnet" "botgauge-app-public-2" {
  cidr_block         = "10.0.2.0/24"
  vpc_id             = aws_vpc.botgauge-app.id
  availability_zone  = "us-west-2b"
}

# Create private subnets in different AZs
resource "aws_subnet" "botgauge-app-private" {
  cidr_block         = "10.0.3.0/24"
  vpc_id             = aws_vpc.botgauge-app.id
  availability_zone  = "us-west-2a"
}

resource "aws_subnet" "botgauge-app-private-2" {
  cidr_block         = "10.0.4.0/24"
  vpc_id             = aws_vpc.botgauge-app.id
  availability_zone  = "us-west-2b"
}

# Create an EKS cluster
resource "aws_eks_cluster" "botgauge-app" {
  name     = "botgauge-app"
  role_arn = aws_iam_role.botgauge-app.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.botgauge-app-public.id, 
      aws_subnet.botgauge-app-public-2.id, 
      aws_subnet.botgauge-app-private.id, 
      aws_subnet.botgauge-app-private-2.id
    ]
  }
}
```
### Step 4: Create GitHub Actions Pipeline
Create a GitHub Actions pipeline in the build-and-deploy.yml file and set up secrets on GitHub for AWS access key, secret key, Docker username, and password.

```yaml
Copy code
name: Build and Deploy

on:
  push:
    branches: [ "master" ]
  pull_request:
    branches: [ "master" ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3

    - name: Create Docker image
      run: |
        docker build -t mrankitvish/botgauge-app .
        docker tag mrankitvish/botgauge-app:latest mrankitvish/botgauge-app:latest

    - name: Docker Login
      uses: docker/login-action@v2
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}

    - name: Push Docker image
      run: |
        docker push mrankitvish/botgauge-app:latest

  deploy:
    needs: build
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v1
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-1

    - name: Deploy to EKS
      run: |
        terraform init
        terraform apply -auto-approve
        helm upgrade --install botgauge-app ./helm-chart
```
### Step 5: Create Helm Chart
Create a Helm chart to deploy the Botgauge application on the EKS cluster. Place the Helm chart files in the `helm-chart` directory.

### Step 6: Push Code to GitHub
Push the code to the GitHub repository. The pipeline will be triggered automatically, building and deploying the Botgauge application.
