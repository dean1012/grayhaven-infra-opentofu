resource "digitalocean_reserved_ip" "this" {
  region     = var.region
  droplet_id = var.droplet_id
}
