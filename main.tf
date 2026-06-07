resource "terraform_data" "workspace_guard" {
  input = terraform.workspace

  lifecycle {
    precondition {
      condition     = contains(local.supported_workspaces, terraform.workspace)
      error_message = "Supported workspaces are baseline, staging, and prod."
    }
  }
}

resource "terraform_data" "environment_policy_guard" {
  count = local.is_environment ? 1 : 0

  input = {
    control_bastion_key = local.control_bastion_key
    tls_mode            = local.web_tls_setting
  }

  lifecycle {
    precondition {
      condition     = local.is_environment ? contains(keys(local.bastion_instances), local.control_bastion_key) : true
      error_message = "The compute policy bastions.control_node value must match a bastion instance key."
    }

    precondition {
      condition     = local.is_environment ? contains(["auto", "load_balancer"], local.web_tls_setting) : true
      error_message = "The compute policy web.tls_mode value must be auto or load_balancer."
    }

    precondition {
      condition     = local.is_environment ? contains(["staging", "production"], local.certificate_environment) : true
      error_message = "certificate_environment must be staging or production."
    }

    precondition {
      condition     = length(local.web_instances) > 0 && length(local.bastion_instances) > 0
      error_message = "The compute policy must define at least one bastion and one web host."
    }

    precondition {
      condition     = local.vault_checkout_path != null && trimspace(local.vault_checkout_path) != ""
      error_message = "grayhaven_vault_checkout_path is required for staging and prod workspaces."
    }

    precondition {
      condition     = local.vault_password != null && local.vault_password != ""
      error_message = "A vault password is required for staging and prod workspaces."
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
  for_each = local.bastion_hosts
  source   = "./modules/droplet"

  name                 = each.value.hostname
  region               = var.default_region
  vpc_id               = module.vpc[0].id
  ssh_key_fingerprints = local.ssh_key_fingerprints
  size                 = each.value.size
  image                = each.value.image
  tags                 = each.value.tags
  user_data            = local.bastion_user_data[each.key]
}

module "web" {
  for_each = local.web_hosts
  source   = "./modules/droplet"

  name                 = each.value.hostname
  region               = var.default_region
  vpc_id               = module.vpc[0].id
  ssh_key_fingerprints = local.ssh_key_fingerprints
  size                 = each.value.size
  image                = each.value.image
  tags                 = each.value.tags
  user_data            = local.web_user_data[each.key]
}

module "bastion_firewall" {
  count  = local.is_environment ? 1 : 0
  source = "./modules/firewall"

  name        = "${local.client_name}-sec-${local.environment}-bastion-fw"
  target_tags = [digitalocean_tag.bastion_scope[0].name]

  inbound_rules  = lookup(local.firewall_rules, "bastion", { inbound = [], outbound = [] }).inbound
  outbound_rules = lookup(local.firewall_rules, "bastion", { inbound = [], outbound = [] }).outbound
}

module "web_firewall" {
  count  = local.is_environment ? 1 : 0
  source = "./modules/firewall"

  name        = "${local.client_name}-core-${local.environment}-web-fw"
  target_tags = [digitalocean_tag.web_scope[0].name]

  inbound_rules  = lookup(local.firewall_rules, "web", { inbound = [], outbound = [] }).inbound
  outbound_rules = lookup(local.firewall_rules, "web", { inbound = [], outbound = [] }).outbound
}
