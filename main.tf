module "vpc" {
  source = "./modules/vpc"

  name        = "${local.client_name}-core-${local.environment}-vpc"
  region      = var.default_region
  vpc_cidr    = var.default_vpc_cidr
  description = "Production VPC for Grayhaven Systems LLC"
}

module "bastion" {
  source = "./modules/droplet"

  name                 = "${local.client_name}-sec-${local.environment}-bastion-01"
  region               = var.default_region
  vpc_id               = module.vpc.id
  ssh_key_fingerprints = var.ssh_key_fingerprints
  size                 = "s-1vcpu-512mb-10gb"
  image                = var.default_os_image
  tags                 = local.bastion_tags
}

module "bastion_reserved_ip" {
  source = "./modules/reserved-ip"

  region     = var.default_region
  droplet_id = module.bastion.id
}

module "web" {
  source = "./modules/droplet"

  name                 = "${local.client_name}-core-${local.environment}-web-01"
  region               = var.default_region
  vpc_id               = module.vpc.id
  ssh_key_fingerprints = var.ssh_key_fingerprints
  size                 = var.default_droplet_size
  image                = var.default_os_image
  tags                 = local.web_tags
}

module "web_reserved_ip" {
  source = "./modules/reserved-ip"

  region     = var.default_region
  droplet_id = module.web.id
}

module "bastion_firewall" {
  source = "./modules/firewall"

  name        = "${local.client_name}-sec-${local.environment}-bastion-fw"
  target_tags = [digitalocean_tag.bastion_scope.name]

  inbound_rules = [
    {
      protocol         = "tcp"
      port_range       = "22"
      source_addresses = ["0.0.0.0/0"]
    }
  ]

  outbound_rules = [
    {
      protocol              = "tcp"
      port_range            = "22"
      destination_addresses = [module.vpc.vpc_cidr]
    },
    {
      protocol              = "tcp"
      port_range            = "80"
      destination_addresses = ["0.0.0.0/0"]
    },
    {
      protocol              = "tcp"
      port_range            = "443"
      destination_addresses = ["0.0.0.0/0"]
    },
    {
      protocol              = "udp"
      port_range            = "53"
      destination_addresses = ["0.0.0.0/0"]
    },
    {
      protocol              = "tcp"
      port_range            = "53"
      destination_addresses = ["0.0.0.0/0"]
    }
  ]
}

module "web_firewall" {
  source = "./modules/firewall"

  name        = "${local.client_name}-core-${local.environment}-web-fw"
  target_tags = [digitalocean_tag.web_scope.name]

  inbound_rules = [
    {
      protocol    = "tcp"
      port_range  = "22"
      source_tags = [digitalocean_tag.bastion_scope.name]
    },
    {
      protocol         = "tcp"
      port_range       = "80"
      source_addresses = ["0.0.0.0/0"]
    },
    {
      protocol         = "tcp"
      port_range       = "443"
      source_addresses = ["0.0.0.0/0"]
    }
  ]

  outbound_rules = [
    {
      protocol              = "tcp"
      port_range            = "80"
      destination_addresses = ["0.0.0.0/0"]
    },
    {
      protocol              = "tcp"
      port_range            = "443"
      destination_addresses = ["0.0.0.0/0"]
    },
    {
      protocol              = "udp"
      port_range            = "53"
      destination_addresses = ["0.0.0.0/0"]
    },
    {
      protocol              = "tcp"
      port_range            = "53"
      destination_addresses = ["0.0.0.0/0"]
    }
  ]
}
