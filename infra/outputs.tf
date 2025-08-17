output "region" {
  description = "Deployment region"
  value       = var.aws_region
}

output "default_vpc_id" {
  description = "Default VPC ID used for the demo"
  value       = data.aws_vpc.default.id
}

output "default_subnet_ids" {
  description = "Default subnet IDs"
  value       = data.aws_subnets.default.ids
}
