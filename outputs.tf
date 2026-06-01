output "bastion_public_ip" {
  description = "Public IPv4 address of the bastion host"
  value       = module.bastion.ipv4_address
}

output "bastion_private_ipv4_address" {
  description = "Private IPv4 address of the bastion host"
  value       = module.bastion.private_ipv4_address
}

output "web_public_ip" {
  description = "Public IPv4 address of the web host"
  value       = module.web.ipv4_address
}

output "web_private_ipv4_address" {
  description = "Private IPv4 address of the web host"
  value       = module.web.private_ipv4_address
}
