locals {
  #############################################################################
  # Repository and workspace identity
  #############################################################################

  client_name            = "grayhaven"
  client_domain          = "grayhavensystems.com"
  personal_domain        = "jerry-smith.net"
  supported_workspaces   = ["baseline", "staging", "prod"]
  environment_workspaces = ["staging", "prod"]
  environment            = terraform.workspace
  is_baseline            = local.environment == "baseline"
  is_environment         = contains(local.environment_workspaces, local.environment)
  is_prod                = local.environment == "prod"

  config_repo_ref  = local.is_prod ? "main" : var.grayhaven_config_repo_ref
  infra_policy_ref = local.is_prod ? "main" : var.grayhaven_infra_policy_repo_ref
  vault_repo_ref   = local.is_prod ? "main" : "staging"

  state_encryption_passphrase = (
    local.environment == "baseline" ? var.state_encryption_passphrase_baseline :
    local.environment == "staging" ? var.state_encryption_passphrase_staging :
    local.environment == "prod" ? var.state_encryption_passphrase_prod :
    coalesce(
      var.state_encryption_passphrase_baseline,
      var.state_encryption_passphrase_staging,
      var.state_encryption_passphrase_prod,
    )
  )
  state_encryption_previous_passphrase = coalesce(
    local.environment == "baseline" ? var.state_encryption_previous_passphrase_baseline : null,
    local.environment == "staging" ? var.state_encryption_previous_passphrase_staging : null,
    local.environment == "prod" ? var.state_encryption_previous_passphrase_prod : null,
    local.state_encryption_passphrase,
  )

  environment_vpc_cidrs = {
    staging = "10.20.0.0/16"
    prod    = "10.30.0.0/16"
  }

  #############################################################################
  # Shared selectors and committed policy
  #############################################################################

  policy_workspace = contains(local.supported_workspaces, local.environment) ? local.environment : "baseline"
  policy_directory = "${path.module}/policy/${local.policy_workspace}"
  common_tags = [
    "client-${local.client_name}",
    "env-${local.environment}",
    "managed-by-opentofu",
    "configured-by-ansible",
    "tls-mode-${replace(local.effective_tls_mode, "_", "-")}"
  ]

  compute_policy_path = coalesce(var.grayhaven_test_compute_policy_path, "${local.policy_directory}/compute.yml")

  compute_policy = (
    local.is_environment
    ? yamldecode(file(local.compute_policy_path))
    : {
      bastions = {
        control_node = ""
        instances    = {}
      }
      web = {
        tls_mode  = "auto"
        instances = {}
      }
    }
  )

  firewall_policy_path = "${local.policy_directory}/firewall.yml"
  firewall_policy      = yamldecode(file(local.firewall_policy_path))

  vault_checkout_path = coalesce(
    var.grayhaven_vault_checkout_path,
    abspath("${path.module}/../grayhaven-vault"),
  )

  # Environment workspaces read config.yml from the intended vault Git ref, not
  # from whichever branch is checked out in the local vault working tree.
  vault_config = (
    local.is_environment
    ? yamldecode(data.external.vault_config[0].result.config_yml)
    : yamldecode(file("${path.module}/policy/default-vault-config.yml"))
  )

  vault_password = !local.is_environment ? null : (
    local.is_prod
    ? var.grayhaven_vault_password_prod
    : var.grayhaven_vault_password_staging
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
  use_load_balancer = (
    local.is_environment
    ? local.web_tls_setting == "load_balancer" || (
      local.web_tls_setting == "auto" && length(local.web_instances) > 1
    )
    : false
  )

  effective_tls_mode = local.is_environment ? (
    local.use_load_balancer ? "load_balancer" : "host"
  ) : "host"

  control_bastion_key = local.is_environment ? local.compute_policy.bastions.control_node : ""
  primary_web_key     = local.is_environment ? try(sort(keys(local.web_instances))[0], "") : ""

  environment_hostname_suffix = local.is_prod ? local.client_domain : "staging.${local.client_domain}"

  #############################################################################
  # Host inventory and cloud-init handoff
  #############################################################################

  web_domain_names = local.is_environment ? flatten([
    for domain_key, site in local.environment_apex_dns : concat(
      [site.site_name],
      contains(keys(local.environment_web_alias_dns), domain_key) ? [
        "${local.environment_web_alias_dns[domain_key].www_name}.${site.domain}",
        "${local.environment_web_alias_dns[domain_key].dev_name}.${site.domain}"
      ] : []
    )
  ]) : []

  firewall_tag_names = local.is_environment ? {
    bastion = digitalocean_tag.bastion_scope[0].name
    web     = digitalocean_tag.web_scope[0].name
  } : {}

  bastion_hosts = {
    for key, instance in local.bastion_instances : key => {
      index           = instance.index
      hostname        = format("%s-sec-%s-bastion-%02d.%s", local.client_name, local.environment, instance.index, local.environment_hostname_suffix)
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
      hostname = format("%s-core-%s-web-%02d.%s", local.client_name, local.environment, instance.index, local.environment_hostname_suffix)
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
