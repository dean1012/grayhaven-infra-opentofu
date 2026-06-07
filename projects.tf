resource "digitalocean_project" "grayhaven" {
  count = local.is_baseline ? 1 : 0

  name        = "grayhaven"
  description = "Infrastructure project for Grayhaven Systems LLC"
  purpose     = "Web Application"
  environment = "Production"
  is_default  = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_project_resources" "environment" {
  count = local.is_environment ? 1 : 0

  project = data.digitalocean_project.grayhaven[0].id

  resources = concat(
    [for droplet in module.bastion : droplet.urn],
    [for droplet in module.web : droplet.urn],
    local.use_load_balancer ? [digitalocean_loadbalancer.web[0].urn] : []
  )
}
