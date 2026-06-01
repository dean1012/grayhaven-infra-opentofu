output "id" {
  description = "DigitalOcean droplet ID"
  value       = digitalocean_droplet.this.id
}

output "urn" {
  description = "DigitalOcean droplet URN"
  value       = digitalocean_droplet.this.urn
}

output "name" {
  description = "DigitalOcean droplet name"
  value       = digitalocean_droplet.this.name
}

output "public_ipv4_address" {
  description = "DigitalOcean droplet public IPv4 address"
  value       = digitalocean_droplet.this.ipv4_address
}

output "private_ipv4_address" {
  description = "DigitalOcean droplet private IPv4 address"
  value       = digitalocean_droplet.this.ipv4_address_private
}
