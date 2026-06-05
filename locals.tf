locals {
  client_name          = "grayhaven"
  client_domain        = "grayhavensystems.com"
  personal_domain      = "jerry-smith.net"
  supported_workspaces = ["baseline", "staging", "prod"]
  environment          = terraform.workspace
  is_baseline          = local.environment == "baseline"
  is_environment       = contains(["staging", "prod"], local.environment)
  is_prod              = local.environment == "prod"

  environment_vpc_cidrs = {
    staging = "10.20.0.0/16"
    prod    = "10.30.0.0/16"
  }

  environment_dns = {
    grayhaven = {
      domain       = local.client_domain
      site_name    = local.is_prod ? local.client_domain : "staging.${local.client_domain}"
      www_name     = local.is_prod ? "www" : "www.staging"
      dev_name     = local.is_prod ? "dev" : "dev.staging"
      env_root     = local.is_prod ? "@" : "staging"
      cname_target = local.is_prod ? "@" : "staging.${local.client_domain}."
    }

    personal = {
      domain       = local.personal_domain
      site_name    = local.is_prod ? local.personal_domain : "staging.${local.personal_domain}"
      www_name     = local.is_prod ? "www" : "www.staging"
      dev_name     = local.is_prod ? "dev" : "dev.staging"
      env_root     = local.is_prod ? "@" : "staging"
      cname_target = local.is_prod ? "@" : "staging.${local.personal_domain}."
    }
  }

  ssh_key_fingerprints = [
    "2e:7c:fa:e9:85:22:4d:1a:ca:e4:b0:6d:01:c5:36:ed"
  ]

  common_tags = [
    "client-${local.client_name}",
    "env-${local.environment}",
    "managed-by-opentofu",
    "configured-by-ansible"
  ]

  bastion_hostname = local.is_prod ? "${local.client_name}-sec-${local.environment}-bastion-01.${local.client_domain}" : "${local.client_name}-sec-${local.environment}-bastion-01.staging.${local.client_domain}"

  bastion_tags = concat(local.common_tags, [
    "project-sec",
    "role-bastion",
    "scope-${local.client_name}-sec-${local.environment}-bastion"
  ])

  web_hostname = local.is_prod ? "${local.client_name}-core-${local.environment}-web-01.${local.client_domain}" : "${local.client_name}-core-${local.environment}-web-01.staging.${local.client_domain}"

  web_tags = concat(local.common_tags, [
    "project-core",
    "role-web",
    "scope-${local.client_name}-core-${local.environment}-web"
  ])

  droplet_dns_records = local.is_environment ? {
    bastion = {
      domain = local.client_domain
      name   = trimsuffix(module.bastion[0].name, ".${local.client_domain}")
      value  = module.bastion[0].public_ipv4_address
    }

    web = {
      domain = local.client_domain
      name   = trimsuffix(module.web[0].name, ".${local.client_domain}")
      value  = module.web[0].public_ipv4_address
    }
  } : {}

  bastion_bootstrap_vars = merge({
    grayhaven_hostname                         = local.bastion_hostname
    grayhaven_environment                      = local.environment
    grayhaven_role                             = "bastion"
    grayhaven_config_repo_ref                  = var.grayhaven_config_repo_ref
    grayhaven_root_password_hash               = var.grayhaven_root_password_hash
    grayhaven_ansible_control_private_key      = var.grayhaven_ansible_control_private_key
    grayhaven_discord_webhook_url              = var.grayhaven_discord_webhook_url
    grayhaven_digitalocean_inventory_api_token = var.grayhaven_digitalocean_inventory_api_token
    grayhaven_jsmith_password_hash             = var.grayhaven_jsmith_password_hash
    grayhaven_jsmith_public_key                = var.grayhaven_jsmith_public_key
    }, var.grayhaven_certbot_environment == null ? {} : {
    grayhaven_certbot_environment = var.grayhaven_certbot_environment
  })

  web_bootstrap_vars = merge({
    grayhaven_hostname                     = local.web_hostname
    grayhaven_environment                  = local.environment
    grayhaven_role                         = "web"
    grayhaven_config_repo_ref              = var.grayhaven_config_repo_ref
    grayhaven_root_password_hash           = var.grayhaven_root_password_hash
    grayhaven_ansible_control_public_key   = var.grayhaven_ansible_control_public_key
    grayhaven_dev_basic_auth_htpasswd_line = var.grayhaven_dev_basic_auth_htpasswd_line
    grayhaven_digitalocean_dns_api_token   = var.grayhaven_digitalocean_dns_api_token
    }, var.grayhaven_certbot_environment == null ? {} : {
    grayhaven_certbot_environment = var.grayhaven_certbot_environment
  })

  bastion_user_data = templatefile("${path.module}/templates/cloud-init/bootstrap-vars.yml.tftpl", {
    bootstrap_vars_yaml = yamlencode(local.bastion_bootstrap_vars)
    config_repo_ref     = var.grayhaven_config_repo_ref
  })

  web_user_data = templatefile("${path.module}/templates/cloud-init/bootstrap-vars.yml.tftpl", {
    bootstrap_vars_yaml = yamlencode(local.web_bootstrap_vars)
    config_repo_ref     = var.grayhaven_config_repo_ref
  })
}
