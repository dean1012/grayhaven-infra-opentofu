output "urn" {
  description = "DigitalOcean reserved IP URN"
  value       = digitalocean_reserved_ip.this.urn
}

output "ip_address" {
  description = "DigitalOcean reserved IP address"
  value       = digitalocean_reserved_ip.this.ip_address
}
