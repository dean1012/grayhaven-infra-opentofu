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
