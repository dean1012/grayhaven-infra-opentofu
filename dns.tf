locals {
  dns_policy  = yamldecode(file("${path.module}/policy/dns.yml"))
  dns_ttl     = try(local.dns_policy.ttl, 300)
  dns_domains = local.dns_policy.domains

  dns_protected_records = merge(flatten([
    for domain_key, domain in local.dns_domains : [
      for record_key, record in try(domain.protected_records, {}) : {
        "${domain_key}.${record_key}" = {
          domain_key = domain_key
          record     = record
        }
      }
    ]
  ])...)

  environment_dns = local.is_environment ? {
    for domain_key, domain in local.dns_domains : domain_key => {
      domain       = domain.name
      site_name    = local.is_prod ? domain.name : "staging.${domain.name}"
      www_name     = local.is_prod ? "www" : "www.staging"
      dev_name     = local.is_prod ? "dev" : "dev.staging"
      env_root     = local.is_prod ? "@" : "staging"
      cname_target = local.is_prod ? "@" : "staging.${domain.name}."
    } if try(domain.environment_web, false)
  } : {}
}

data "digitalocean_domain" "managed" {
  for_each = local.is_environment ? local.dns_domains : {}

  name = each.value.name
}

###############################################################################
# Baseline DNS zones and shared records
###############################################################################

resource "digitalocean_domain" "managed" {
  for_each = local.is_baseline ? local.dns_domains : {}

  name = each.value.name

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "baseline_protected" {
  for_each = local.is_baseline ? local.dns_protected_records : {}

  domain   = digitalocean_domain.managed[each.value.domain_key].name
  type     = each.value.record.type
  name     = each.value.record.name
  value    = each.value.record.value
  priority = try(each.value.record.priority, null)
  flags    = try(each.value.record.flags, null)
  tag      = try(each.value.record.tag, null)
  ttl      = try(each.value.record.ttl, local.dns_ttl)

  lifecycle {
    prevent_destroy = true
  }
}

###############################################################################
# Environment DNS records
###############################################################################

resource "digitalocean_record" "web_root_a" {
  for_each = local.is_environment ? local.environment_dns : {}

  domain = each.value.domain
  type   = "A"
  name   = each.value.env_root
  value  = local.use_load_balancer ? digitalocean_loadbalancer.web[0].ip : try(module.web[local.primary_web_key].public_ipv4_address, "")
  ttl    = local.dns_ttl

  depends_on = [data.digitalocean_domain.managed]
}

resource "digitalocean_record" "web_www_cname" {
  for_each = local.is_environment ? local.environment_dns : {}

  domain = each.value.domain
  type   = "CNAME"
  name   = each.value.www_name
  value  = each.value.cname_target
  ttl    = local.dns_ttl

  depends_on = [data.digitalocean_domain.managed]
}

resource "digitalocean_record" "web_dev_cname" {
  for_each = local.is_environment ? local.environment_dns : {}

  domain = each.value.domain
  type   = "CNAME"
  name   = each.value.dev_name
  value  = each.value.cname_target
  ttl    = local.dns_ttl

  depends_on = [data.digitalocean_domain.managed]
}

resource "digitalocean_record" "grayhaven_droplet_a" {
  for_each = local.droplet_dns_records

  domain = each.value.domain
  type   = "A"
  name   = each.value.name
  value  = each.value.value
  ttl    = local.dns_ttl

  depends_on = [data.digitalocean_domain.managed]
}

resource "digitalocean_record" "grayhaven_bastion_a" {
  count = local.is_environment ? 1 : 0

  domain = local.client_domain
  type   = "A"
  name   = local.is_prod ? "bastion" : "bastion.staging"
  value  = try(module.bastion[local.control_bastion_key].public_ipv4_address, "")
  ttl    = local.dns_ttl

  depends_on = [data.digitalocean_domain.managed]
}
