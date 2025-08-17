provider "aws" {
  region = var.aws_region
}

# keep names/tags consistent across resources
locals {
  common_tags = {
    Project = var.project_name
    Env     = "demo"
    Owner   = "ekong"
  }
}

# Use the default VPC to keep this lab simple
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# (We’ll add IAM, ECR, EB, S3, EC2, and CloudWatch here in Step 6.)
