variable "project_name" {
  description = "Name prefix for resources"
  type        = string
  default     = "node-devops-lab-20250817"
}

variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-west-2"
}

# temporarily used for SSH/Jenkins UI while bootstrapping
variable "my_ip_cidr" {
  description = "Your public IP in CIDR, e.g. 203.0.113.10/32"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh_key_name" {
  description = "Existing EC2 key pair name"
  type        = string
  default     = "ekong-iac"
}

variable "eb_bundle_bucket" {
  description = "Globally-unique S3 bucket for EB bundles (zip files)"
  type        = string
}

# Elastic Beanstalk Docker platform (can update later via console if version changes)
variable "eb_platform_arn" {
  description = "EB Docker on AL2 platform ARN"
  type        = string
  default     = "arn:aws:elasticbeanstalk:eu-west-2::platform/Docker running on 64bit Amazon Linux 2023/4.6.3"
}
