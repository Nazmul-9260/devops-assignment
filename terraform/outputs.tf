output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.assessment_vpc.id
}

output "server_instance_id" {
  description = "EC2 Instance ID for the assessment server"
  value       = aws_instance.app_server.id
}
