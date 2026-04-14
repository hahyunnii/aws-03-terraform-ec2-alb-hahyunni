output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web.id
}

output "instance_public_ip" {
  description = "Public IP address used for browser and curl tests"
  value       = aws_instance.web.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name assigned by AWS"
  value       = aws_instance.web.public_dns
}

output "selected_subnet_id" {
  description = "Subnet chosen from the default VPC"
  value       = local.selected_subnet_id
}

output "security_group_id" {
  description = "Security group attached to the instance"
  value       = aws_security_group.web.id
}
