locals {
  #############################################################################
  # Repository and workspace identity
  #############################################################################

  client_name          = "grayhaven"
  client_domain        = "grayhavensystems.com"
  personal_domain      = "jerry-smith.net"
  supported_workspaces = ["baseline", "staging", "prod"]
  environment          = terraform.workspace
  is_baseline          = local.environment == "baseline"
  is_environment       = contains(["staging", "prod"], local.environment)
  is_prod              = local.environment == "prod"
  config_repo_ref      = local.is_prod ? "main" : var.grayhaven_config_repo_ref
  infra_policy_ref     = local.is_prod ? "main" : var.grayhaven_infra_policy_repo_ref
  vault_repo_ref       = local.is_prod ? "main" : "staging"

  environment_vpc_cidrs = {
    staging = "10.20.0.0/16"
    prod    = "10.30.0.0/16"
  }

  #############################################################################
  # Shared selectors and committed policy
  #############################################################################

  ssh_key_fingerprints = [
    "2e:7c:fa:e9:85:22:4d:1a:ca:e4:b0:6d:01:c5:36:ed"
  ]

  common_tags = [
    "client-${local.client_name}",
    "env-${local.environment}",
    "managed-by-opentofu",
    "configured-by-ansible",
    "tls-mode-${replace(local.effective_tls_mode, "_", "-")}"
  ]

  compute_policy = local.is_environment ? yamldecode(file("${path.module}/policy/compute.yml")) : {
    bastions = {
      control_node = ""
      instances    = {}
    }
    web = {
      tls_mode  = "auto"
      instances = {}
    }
  }
  firewall_policy     = yamldecode(file("${path.module}/policy/firewall/${local.is_environment ? local.environment : "staging"}.yml"))
  vault_checkout_path = coalesce(var.grayhaven_vault_checkout_path, abspath("${path.module}/../grayhaven-vault"))
  vault_config = yamldecode(file(
    local.is_environment
    ? "${local.vault_checkout_path}/config.yml"
    : "${path.module}/policy/default-vault-config.yml"
  ))
  vault_password = !local.is_environment ? null : (
    local.is_prod
    ? try(coalesce(var.grayhaven_vault_password, var.grayhaven_vault_password_prod), null)
    : try(coalesce(var.grayhaven_vault_password, var.grayhaven_vault_password_staging), null)
  )
  certificate_env_auto = local.is_prod ? "production" : "staging"

  certificate_environment = local.is_environment ? coalesce(
    var.grayhaven_certificate_environment,
    try(local.vault_config.certificate_environment, null),
    local.certificate_env_auto
  ) : "staging"

  bastion_instances = local.is_environment ? local.compute_policy.bastions.instances : {}
  web_instances     = local.is_environment ? local.compute_policy.web.instances : {}
  web_tls_setting   = local.is_environment ? try(local.compute_policy.web.tls_mode, "auto") : "auto"
  # In auto mode, a single web host terminates TLS locally; multiple web hosts
  # use a DigitalOcean load balancer so certificate and backend behavior stay
  # consistent during scale-out.
  use_load_balancer = local.is_environment ? local.web_tls_setting == "load_balancer" || (local.web_tls_setting == "auto" && length(local.web_instances) > 1) : false
  effective_tls_mode = local.is_environment ? (
    local.use_load_balancer ? "load_balancer" : "host"
  ) : "host"
  control_bastion_key = local.is_environment ? local.compute_policy.bastions.control_node : ""
  primary_web_key     = local.is_environment ? try(sort(keys(local.web_instances))[0], "") : ""

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

  #############################################################################
  # Host inventory and cloud-init handoff
  #############################################################################

  web_domain_names = local.is_environment ? flatten([
    for site in local.environment_dns : [
      site.site_name,
      "${site.www_name}.${site.domain}",
      "${site.dev_name}.${site.domain}"
    ]
  ]) : []

  firewall_tag_names = local.is_environment ? {
    bastion = digitalocean_tag.bastion_scope[0].name
    web     = digitalocean_tag.web_scope[0].name
  } : {}

  bastion_hosts = {
    for key, instance in local.bastion_instances : key => {
      index           = instance.index
      hostname        = local.is_prod ? "${local.client_name}-sec-${local.environment}-bastion-${format("%02d", instance.index)}.${local.client_domain}" : "${local.client_name}-sec-${local.environment}-bastion-${format("%02d", instance.index)}.staging.${local.client_domain}"
      is_control_node = key == local.control_bastion_key
      size            = try(instance.size, var.default_droplet_size)
      image           = try(instance.image, var.default_os_image)
      tags = concat(local.common_tags, [
        "project-sec",
        "role-bastion",
        "scope-${local.client_name}-sec-${local.environment}-bastion",
        "bastion-${format("%02d", instance.index)}",
        key == local.control_bastion_key ? "control-node" : "control-capable"
      ])
    }
  }

  web_hosts = {
    for key, instance in local.web_instances : key => {
      index    = instance.index
      hostname = local.is_prod ? "${local.client_name}-core-${local.environment}-web-${format("%02d", instance.index)}.${local.client_domain}" : "${local.client_name}-core-${local.environment}-web-${format("%02d", instance.index)}.staging.${local.client_domain}"
      size     = try(instance.size, var.default_droplet_size)
      image    = try(instance.image, var.default_os_image)
      tags = concat(local.common_tags, [
        "project-core",
        "role-web",
        "scope-${local.client_name}-core-${local.environment}-web",
        "web-${format("%02d", instance.index)}"
      ])
    }
  }

  bastion_bootstrap_vars = {
    for key, host in local.bastion_hosts : key => {
      grayhaven_hostname                   = host.hostname
      grayhaven_environment                = local.environment
      grayhaven_role                       = "bastion"
      grayhaven_is_control_node            = host.is_control_node
      grayhaven_control_bastion_key        = local.control_bastion_key
      grayhaven_config_repo_ref            = local.config_repo_ref
      grayhaven_infra_policy_repo_ref      = local.infra_policy_ref
      grayhaven_vault_repo_url             = var.grayhaven_vault_repo_url
      grayhaven_vault_repo_ref             = local.vault_repo_ref
      grayhaven_vault_password             = local.vault_password
      grayhaven_ansible_deploy_public_key  = var.grayhaven_ansible_deploy_public_key
      grayhaven_ansible_deploy_private_key = var.grayhaven_ansible_deploy_private_key
      grayhaven_certificate_environment    = local.certificate_environment
      grayhaven_tls_mode                   = local.effective_tls_mode
    }
  }

  web_bootstrap_vars = {
    for key, host in local.web_hosts : key => {
      grayhaven_hostname                  = host.hostname
      grayhaven_environment               = local.environment
      grayhaven_role                      = "web"
      grayhaven_config_repo_ref           = local.config_repo_ref
      grayhaven_infra_policy_repo_ref     = local.infra_policy_ref
      grayhaven_control_bastion_key       = local.control_bastion_key
      grayhaven_ansible_deploy_public_key = var.grayhaven_ansible_deploy_public_key
      grayhaven_certificate_environment   = local.certificate_environment
      grayhaven_tls_mode                  = local.effective_tls_mode
    }
  }

  bastion_user_data = {
    for key, bootstrap_vars in local.bastion_bootstrap_vars : key => templatefile("${path.module}/templates/cloud-init/bootstrap-vars.yml.tftpl", {
      bootstrap_vars_yaml = yamlencode(bootstrap_vars)
      config_repo_ref     = local.config_repo_ref
    })
  }

  web_user_data = {
    for key, bootstrap_vars in local.web_bootstrap_vars : key => templatefile("${path.module}/templates/cloud-init/bootstrap-vars.yml.tftpl", {
      bootstrap_vars_yaml = yamlencode(bootstrap_vars)
      config_repo_ref     = local.config_repo_ref
    })
  }

  #############################################################################
  # DNS and firewall policy expansion
  #############################################################################

  droplet_dns_records = local.is_environment ? merge(
    {
      for key, host in local.bastion_hosts : "bastion-${key}" => {
        domain = local.client_domain
        name   = trimsuffix(module.bastion[key].name, ".${local.client_domain}")
        value  = module.bastion[key].public_ipv4_address
      }
    },
    {
      for key, host in local.web_hosts : "web-${key}" => {
        domain = local.client_domain
        name   = trimsuffix(module.web[key].name, ".${local.client_domain}")
        value  = module.web[key].public_ipv4_address
      }
    }
  ) : {}

  firewall_rules = local.is_environment ? {
    for role, policy in local.firewall_policy.firewalls : role => {
      inbound = [
        for rule in try(policy.inbound, []) : {
          protocol         = rule.protocol
          port_range       = rule.port_range
          source_addresses = try(rule.source_addresses, [])
          source_tags      = [for tag in try(rule.source_tags, []) : local.firewall_tag_names[tag]]
        }
      ]
      outbound = [
        for rule in try(policy.outbound, []) : {
          protocol              = rule.protocol
          port_range            = rule.port_range
          destination_addresses = try(rule.destination_addresses, [])
          destination_tags      = [for tag in try(rule.destination_tags, []) : local.firewall_tag_names[tag]]
        }
      ]
    }
  } : {}
}
