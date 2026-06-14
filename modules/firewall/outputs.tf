output "id" {
  description = "DigitalOcean firewall ID"
  value       = digitalocean_firewall.this.id
}

output "inbound_rules" {
  description = "Normalized inbound firewall rules applied by this module"
  value       = var.inbound_rules
}

output "name" {
  description = "DigitalOcean firewall name"
  value       = digitalocean_firewall.this.name
}
