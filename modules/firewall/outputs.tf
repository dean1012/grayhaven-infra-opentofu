output "id" {
  description = "DigitalOcean firewall ID"
  value       = digitalocean_firewall.this.id
}

output "name" {
  description = "DigitalOcean firewall name"
  value       = digitalocean_firewall.this.name
}
