output "bastion_public_ipv4_address" {
  description = "Public IPv4 address of the bastion host"
  value       = local.is_environment ? module.bastion[0].public_ipv4_address : null
}

output "bastion_private_ipv4_address" {
  description = "Private IPv4 address of the bastion host"
  value       = local.is_environment ? module.bastion[0].private_ipv4_address : null
}

output "web_public_ipv4_address" {
  description = "Public IPv4 address of the web host"
  value       = local.is_environment ? module.web[0].public_ipv4_address : null
}

output "web_private_ipv4_address" {
  description = "Private IPv4 address of the web host"
  value       = local.is_environment ? module.web[0].private_ipv4_address : null
}

output "workspace" {
  description = "Active OpenTofu workspace"
  value       = terraform.workspace
}

output "environment_vpc_cidr" {
  description = "CIDR range of the active environment VPC"
  value       = local.is_environment ? module.vpc[0].vpc_cidr : null
}
