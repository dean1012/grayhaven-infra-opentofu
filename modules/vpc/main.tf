resource "digitalocean_vpc" "this" {
  name        = var.name
  region      = var.region
  ip_range    = var.vpc_cidr
  description = var.description
}
