output "region" { value = var.aws_region }

output "default_vpc_id" {
  description = "Default VPC ID"
  value       = data.aws_vpc.default.id
}

output "default_subnet_ids" {
  description = "Default subnet IDs"
  value       = data.aws_subnets.default.ids
}

output "jenkins_url" {
  description = "Temporary direct access for setup"
  value       = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "ecr_repo_url" {
  description = "ECR repository URI"
  value       = aws_ecr_repository.app.repository_url
}

output "eb_cname" {
  description = "Elastic Beanstalk environment CNAME"
  value       = aws_elastic_beanstalk_environment.app_env.cname
}

output "eb_url" {
  description = "Elastic Beanstalk environment URL (HTTP for now)"
  value       = "http://${aws_elastic_beanstalk_environment.app_env.cname}"
}
