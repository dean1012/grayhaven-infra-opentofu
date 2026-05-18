output "bastion_public_ip" {
  description = "Public IPv4 address of the bastion host"
  value       = module.bastion_reserved_ip.ip_address
}

output "web_public_ip" {
  description = "Public IPv4 address of the web host"
  value       = module.web_reserved_ip.ip_address
}
