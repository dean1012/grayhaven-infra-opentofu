resource "terraform_data" "workspace_guard" {
  input = terraform.workspace

  lifecycle {
    precondition {
      condition     = contains(local.supported_workspaces, terraform.workspace)
      error_message = "Supported workspaces are baseline, staging, and prod."
    }
  }
}

data "digitalocean_project" "grayhaven" {
  count = local.is_environment ? 1 : 0

  name = local.client_name
}

resource "digitalocean_vpc" "baseline" {
  count = local.is_baseline ? 1 : 0

  name        = "${local.client_name}-core-baseline-vpc"
  region      = var.default_region
  ip_range    = var.baseline_vpc_cidr
  description = "Baseline default VPC for Grayhaven Systems LLC"

  lifecycle {
    prevent_destroy = true
  }
}

module "vpc" {
  count  = local.is_environment ? 1 : 0
  source = "./modules/vpc"

  name        = "${local.client_name}-core-${local.environment}-vpc"
  region      = var.default_region
  vpc_cidr    = lookup(local.environment_vpc_cidrs, local.environment, var.baseline_vpc_cidr)
  description = "${title(local.environment)} VPC for Grayhaven Systems LLC"
}

module "bastion" {
  count  = local.is_environment ? 1 : 0
  source = "./modules/droplet"

  name                 = local.bastion_hostname
  region               = var.default_region
  vpc_id               = module.vpc[0].id
  ssh_key_fingerprints = local.ssh_key_fingerprints
  size                 = var.default_droplet_size
  image                = var.default_os_image
  tags                 = local.bastion_tags
  user_data            = local.bastion_user_data
}

module "web" {
  count  = local.is_environment ? 1 : 0
  source = "./modules/droplet"

  name                 = local.web_hostname
  region               = var.default_region
  vpc_id               = module.vpc[0].id
  ssh_key_fingerprints = local.ssh_key_fingerprints
  size                 = var.default_droplet_size
  image                = var.default_os_image
  tags                 = local.web_tags
  user_data            = local.web_user_data
}

module "bastion_firewall" {
  count  = local.is_environment ? 1 : 0
  source = "./modules/firewall"

  name        = "${local.client_name}-sec-${local.environment}-bastion-fw"
  target_tags = [digitalocean_tag.bastion_scope[0].name]

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
      destination_addresses = [module.vpc[0].vpc_cidr]
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
    },
    {
      protocol              = "udp"
      port_range            = "123"
      destination_addresses = ["0.0.0.0/0"]
    }
  ]
}

module "web_firewall" {
  count  = local.is_environment ? 1 : 0
  source = "./modules/firewall"

  name        = "${local.client_name}-core-${local.environment}-web-fw"
  target_tags = [digitalocean_tag.web_scope[0].name]

  inbound_rules = [
    {
      protocol    = "tcp"
      port_range  = "22"
      source_tags = [digitalocean_tag.bastion_scope[0].name]
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
    },
    {
      protocol              = "udp"
      port_range            = "123"
      destination_addresses = ["0.0.0.0/0"]
    }
  ]
}
