resource "digitalocean_project" "grayhaven" {
  name        = "grayhaven"
  description = "Infrastructure project for Grayhaven Systems LLC"
  purpose     = "Web Application"
  environment = "Production"
  is_default  = true
}

resource "digitalocean_project_resources" "grayhaven" {
  project = digitalocean_project.grayhaven.id

  resources = [
    module.bastion.urn,
    module.bastion_reserved_ip.urn,
    module.web.urn,
    module.web_reserved_ip.urn,
  ]
}
