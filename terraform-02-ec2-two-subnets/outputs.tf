output "selected_availability_zones" {
  description = "The two Availability Zones chosen for instance placement"
  value       = local.selected_azs
}

output "selected_subnet_ids" {
  description = "The two subnet IDs chosen for instance placement"
  value       = local.selected_subnet_ids
}

output "instance_ids" {
  description = "Instance IDs keyed by logical server name"
  value       = { for name, instance in aws_instance.web : name => instance.id }
}

output "instance_public_ips" {
  description = "Public IPs keyed by logical server name"
  value       = { for name, instance in aws_instance.web : name => instance.public_ip }
}

output "instance_public_dns" {
  description = "Public DNS names keyed by logical server name"
  value       = { for name, instance in aws_instance.web : name => instance.public_dns }
}
