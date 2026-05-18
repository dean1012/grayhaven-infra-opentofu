resource "digitalocean_tag" "bastion_scope" {
  name = "scope-grayhaven-sec-prod-bastion"
}

resource "digitalocean_tag" "web_scope" {
  name = "scope-grayhaven-core-prod-web"
}
