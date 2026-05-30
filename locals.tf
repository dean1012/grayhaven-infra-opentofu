locals {
  client_name   = "grayhaven"
  client_domain = "grayhavensystems.com"
  environment   = "prod"

  ssh_key_fingerprints = [
    "2e:7c:fa:e9:85:22:4d:1a:ca:e4:b0:6d:01:c5:36:ed"
  ]

  common_tags = [
    "client-${local.client_name}",
    "env-${local.environment}",
    "managed-by-opentofu",
    "configured-by-ansible"
  ]

  bastion_hostname = "${local.client_name}-sec-${local.environment}-bastion-01.${local.client_domain}"

  bastion_tags = concat(local.common_tags, [
    "project-sec",
    "role-bastion",
    "scope-grayhaven-sec-prod-bastion"
  ])

  web_hostname = "${local.client_name}-core-${local.environment}-web-01.${local.client_domain}"

  web_tags = concat(local.common_tags, [
    "project-core",
    "role-web",
    "scope-grayhaven-core-prod-web"
  ])

  droplet_dns_records = {
    bastion = {
      name  = trimsuffix(module.bastion.name, ".${local.client_domain}")
      value = module.bastion.ipv4_address
    }

    web = {
      name  = trimsuffix(module.web.name, ".${local.client_domain}")
      value = module.web.ipv4_address
    }
  }

  bastion_bootstrap_vars = {
    grayhaven_hostname                         = local.bastion_hostname
    grayhaven_role                             = "bastion"
    grayhaven_root_password_hash               = var.grayhaven_root_password_hash
    grayhaven_ansible_control_private_key      = var.grayhaven_ansible_control_private_key
    grayhaven_discord_webhook_url              = var.grayhaven_discord_webhook_url
    grayhaven_digitalocean_inventory_api_token = var.grayhaven_digitalocean_inventory_api_token
  }

  web_bootstrap_vars = {
    grayhaven_hostname                     = local.web_hostname
    grayhaven_role                         = "web"
    grayhaven_root_password_hash           = var.grayhaven_root_password_hash
    grayhaven_ansible_control_public_key   = var.grayhaven_ansible_control_public_key
    grayhaven_dev_basic_auth_htpasswd_line = var.grayhaven_dev_basic_auth_htpasswd_line
    grayhaven_digitalocean_dns_api_token   = var.grayhaven_digitalocean_dns_api_token
  }

  bastion_user_data = templatefile("${path.module}/templates/cloud-init/bootstrap-vars.yml.tftpl", {
    bootstrap_vars_yaml = yamlencode(local.bastion_bootstrap_vars)
  })

  web_user_data = templatefile("${path.module}/templates/cloud-init/bootstrap-vars.yml.tftpl", {
    bootstrap_vars_yaml = yamlencode(local.web_bootstrap_vars)
  })
}
