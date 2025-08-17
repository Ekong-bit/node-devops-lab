
########################################
# Provider & context (eu-west-2)
########################################
provider "aws" {
  region = var.aws_region
}

locals {
  common_tags = {
    Project = var.project_name
    Env     = "demo"
    Owner   = "ekong"
  }
}

# Use default VPC to keep the lab simple
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

########################################
# Security Group for Jenkins EC2
########################################
resource "aws_security_group" "jenkins_sg" {
  name        = "${var.project_name}-jenkins-sg"
  description = "Allow SSH and Jenkins UI during bootstrap"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH from your IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  ingress {
    description = "Jenkins UI (TEMP while bootstrapping)"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-jenkins-sg" })
}

########################################
# IAM: Jenkins EC2 role + instance profile
########################################
resource "aws_iam_role" "jenkins_role" {
  name = "${var.project_name}-jenkins-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = local.common_tags
}

resource "aws_iam_policy" "jenkins_policy" {
  name = "${var.project_name}-jenkins-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid : "ECRPushPull",
        Effect : "Allow",
        Action : [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:GetDownloadUrlForLayer"
        ],
        Resource : "*"
      },
      {
        Sid : "S3UploadBundle",
        Effect : "Allow",
        Action : [
          "s3:PutObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ],
        Resource : [
          "arn:aws:s3:::${var.eb_bundle_bucket}",
          "arn:aws:s3:::${var.eb_bundle_bucket}/*"
        ]
      },
      {
        Sid : "ElasticBeanstalkRelease",
        Effect : "Allow",
        Action : [
          "elasticbeanstalk:CreateApplicationVersion",
          "elasticbeanstalk:UpdateEnvironment",
          "elasticbeanstalk:DescribeEnvironments",
          "elasticbeanstalk:DescribeApplicationVersions"
        ],
        Resource : "*"
      }
    ]
  })
  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "jenkins_attach" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = aws_iam_policy.jenkins_policy.arn
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "${var.project_name}-jenkins-profile"
  role = aws_iam_role.jenkins_role.name
}

########################################
# ECR repository (Docker images)
########################################
resource "aws_ecr_repository" "app" {
  name = var.project_name
  image_scanning_configuration { scan_on_push = true }
  force_delete = true
  tags         = local.common_tags
}

########################################
# S3 bucket for EB bundles (Dockerrun zip)
########################################
resource "aws_s3_bucket" "eb_bundles" {
  bucket = var.eb_bundle_bucket
  tags   = merge(local.common_tags, { Name = "${var.project_name}-eb-bundles" })
}
########################################
# IAM for Elastic Beanstalk
########################################

# EC2 role used by EB instances
resource "aws_iam_role" "eb_ec2_role" {
  name = "aws-elasticbeanstalk-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = local.common_tags
}

# Attach standard permissions to the EB EC2 role
resource "aws_iam_role_policy_attachment" "eb_webtier" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "eb_ecr_ro" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eb_cw_agent" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Instance profile that EB requires
resource "aws_iam_instance_profile" "eb_ec2_profile" {
  name = "aws-elasticbeanstalk-ec2-role"
  role = aws_iam_role.eb_ec2_role.name
}

# Service role used by Elastic Beanstalk itself
resource "aws_iam_role" "eb_service_role" {
  name = "aws-elasticbeanstalk-service-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "elasticbeanstalk.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "eb_enhanced_health" {
  role       = aws_iam_role.eb_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

########################################
# Elastic Beanstalk app + environment
########################################
resource "aws_elastic_beanstalk_application" "app" {
  name        = var.project_name
  description = "Dockerized Node.js app deployed from Jenkins"
  tags        = local.common_tags
}

resource "aws_elastic_beanstalk_environment" "app_env" {
  name         = "${var.project_name}-env"
  application  = aws_elastic_beanstalk_application.app.name
  platform_arn = var.eb_platform_arn

  # Tell EB which service role to use
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.eb_service_role.arn
  }

  # EB instances need this instance profile
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }

  # Stream instance logs to CloudWatch Logs, keep 7 days
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = "true"
  }
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "RetentionInDays"
    value     = "7"
  }

  tags = local.common_tags

  depends_on = [
    aws_iam_instance_profile.eb_ec2_profile,
    aws_iam_role.eb_service_role
  ]
}

########################################
# Jenkins EC2 instance
########################################
data "aws_ami" "amzn2" {
  most_recent = true
  owners      = ["137112412989"] # Amazon
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-*"] # tolerate gp2/gp3 suffixes
  }
}

resource "aws_instance" "jenkins" {
  ami                         = data.aws_ami.amzn2.id
  instance_type               = "t3.small"
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  key_name                    = var.ssh_key_name
  iam_instance_profile        = aws_iam_instance_profile.jenkins_profile.name
  associate_public_ip_address = true
  user_data                   = file("${path.module}/user_data_jenkins.sh")

  tags = merge(local.common_tags, { Name = "${var.project_name}-jenkins" })
}

########################################
# CloudWatch alarm: Jenkins CPU high
########################################
resource "aws_cloudwatch_metric_alarm" "jenkins_cpu_high" {
  alarm_name          = "${var.project_name}-jenkins-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Jenkins EC2 CPU > 70% for 10 minutes"
  dimensions = {
    InstanceId = aws_instance.jenkins.id
  }
  tags = local.common_tags
}
