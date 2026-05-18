output "id" {
  description = "DigitalOcean VPC ID"
  value       = digitalocean_vpc.this.id
}

output "name" {
  description = "DigitalOcean VPC name"
  value       = digitalocean_vpc.this.name
}

output "vpc_cidr" {
  description = "DigitalOcean VPC CIDR range"
  value       = digitalocean_vpc.this.ip_range
}
