output "id" {
  description = "DigitalOcean droplet ID"
  value       = digitalocean_droplet.this.id
}

output "name" {
  description = "DigitalOcean droplet name"
  value       = digitalocean_droplet.this.name
}

output "ipv4_address" {
  description = "DigitalOcean droplet public IPv4 address"
  value       = digitalocean_droplet.this.ipv4_address
}
