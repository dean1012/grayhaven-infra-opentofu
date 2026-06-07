resource "digitalocean_droplet" "this" {
  name      = var.name
  region    = var.region
  vpc_uuid  = var.vpc_id
  ssh_keys  = var.ssh_key_fingerprints
  size      = var.size
  image     = var.image
  tags      = var.tags
  user_data = var.user_data

  lifecycle {
    ignore_changes = [user_data]
  }
}
