locals {
  dns_ttl = 300
}

data "digitalocean_domain" "grayhaven_systems" {
  count = local.is_environment ? 1 : 0

  name = local.client_domain
}

data "digitalocean_domain" "jerry_smith" {
  count = local.is_environment ? 1 : 0

  name = local.personal_domain
}

###############################################################################
# Baseline DNS zones and shared records
###############################################################################

resource "digitalocean_domain" "grayhaven_systems" {
  count = local.is_baseline ? 1 : 0

  name = local.client_domain

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_domain" "jerry_smith" {
  count = local.is_baseline ? 1 : 0

  name = local.personal_domain

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "grayhaven_caa_letsencrypt" {
  count = local.is_baseline ? 1 : 0

  domain = digitalocean_domain.grayhaven_systems[0].name
  type   = "CAA"
  name   = "@"
  flags  = 0
  tag    = "issue"
  value  = "letsencrypt.org."
  ttl    = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "grayhaven_caa_no_wildcards" {
  count = local.is_baseline ? 1 : 0

  domain = digitalocean_domain.grayhaven_systems[0].name
  type   = "CAA"
  name   = "@"
  flags  = 0
  tag    = "issuewild"
  value  = ";."
  ttl    = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "jerry_caa_letsencrypt" {
  count = local.is_baseline ? 1 : 0

  domain = digitalocean_domain.jerry_smith[0].name
  type   = "CAA"
  name   = "@"
  flags  = 0
  tag    = "issue"
  value  = "letsencrypt.org."
  ttl    = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "jerry_caa_no_wildcards" {
  count = local.is_baseline ? 1 : 0

  domain = digitalocean_domain.jerry_smith[0].name
  type   = "CAA"
  name   = "@"
  flags  = 0
  tag    = "issuewild"
  value  = ";."
  ttl    = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "grayhaven_mx" {
  count = local.is_baseline ? 1 : 0

  domain   = digitalocean_domain.grayhaven_systems[0].name
  type     = "MX"
  name     = "@"
  value    = "mail.protonmail.ch."
  priority = 10
  ttl      = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "grayhaven_mx_secondary" {
  count = local.is_baseline ? 1 : 0

  domain   = digitalocean_domain.grayhaven_systems[0].name
  type     = "MX"
  name     = "@"
  value    = "mailsec.protonmail.ch."
  priority = 20
  ttl      = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "grayhaven_spf_txt" {
  count = local.is_baseline ? 1 : 0

  domain = digitalocean_domain.grayhaven_systems[0].name
  type   = "TXT"
  name   = "@"
  value  = "v=spf1 include:_spf.protonmail.ch ~all"
  ttl    = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "grayhaven_protonmail_verification_txt" {
  count = local.is_baseline ? 1 : 0

  domain = digitalocean_domain.grayhaven_systems[0].name
  type   = "TXT"
  name   = "@"
  value  = "protonmail-verification=37192d42ca1137baa2a213f8969d2722de1bedb5"
  ttl    = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "grayhaven_dmarc_txt" {
  count = local.is_baseline ? 1 : 0

  domain = digitalocean_domain.grayhaven_systems[0].name
  type   = "TXT"
  name   = "_dmarc"
  value  = "v=DMARC1; p=quarantine"
  ttl    = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "grayhaven_protonmail_dkim_cname" {
  count = local.is_baseline ? 1 : 0

  domain = digitalocean_domain.grayhaven_systems[0].name
  type   = "CNAME"
  name   = "protonmail._domainkey"
  value  = "protonmail.domainkey.dj7hsgypqb4rzqit4jcxqi4illhiguvk4332qwdy7peaxv4f7gcsq.domains.proton.ch."
  ttl    = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "grayhaven_protonmail_dkim2_cname" {
  count = local.is_baseline ? 1 : 0

  domain = digitalocean_domain.grayhaven_systems[0].name
  type   = "CNAME"
  name   = "protonmail2._domainkey"
  value  = "protonmail2.domainkey.dj7hsgypqb4rzqit4jcxqi4illhiguvk4332qwdy7peaxv4f7gcsq.domains.proton.ch."
  ttl    = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "grayhaven_protonmail_dkim3_cname" {
  count = local.is_baseline ? 1 : 0

  domain = digitalocean_domain.grayhaven_systems[0].name
  type   = "CNAME"
  name   = "protonmail3._domainkey"
  value  = "protonmail3.domainkey.dj7hsgypqb4rzqit4jcxqi4illhiguvk4332qwdy7peaxv4f7gcsq.domains.proton.ch."
  ttl    = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "jerry_mx" {
  count = local.is_baseline ? 1 : 0

  domain   = digitalocean_domain.jerry_smith[0].name
  type     = "MX"
  name     = "@"
  value    = "mail.protonmail.ch."
  priority = 10
  ttl      = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "jerry_mx_secondary" {
  count = local.is_baseline ? 1 : 0

  domain   = digitalocean_domain.jerry_smith[0].name
  type     = "MX"
  name     = "@"
  value    = "mailsec.protonmail.ch."
  priority = 20
  ttl      = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "jerry_spf_txt" {
  count = local.is_baseline ? 1 : 0

  domain = digitalocean_domain.jerry_smith[0].name
  type   = "TXT"
  name   = "@"
  value  = "v=spf1 include:_spf.protonmail.ch ~all"
  ttl    = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "jerry_protonmail_verification_txt" {
  count = local.is_baseline ? 1 : 0

  domain = digitalocean_domain.jerry_smith[0].name
  type   = "TXT"
  name   = "@"
  value  = "protonmail-verification=455409ec796cac0c93dbb4ec2e894e5e0c2766a6"
  ttl    = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "jerry_dmarc_txt" {
  count = local.is_baseline ? 1 : 0

  domain = digitalocean_domain.jerry_smith[0].name
  type   = "TXT"
  name   = "_dmarc"
  value  = "v=DMARC1; p=quarantine"
  ttl    = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "jerry_protonmail_dkim_cname" {
  count = local.is_baseline ? 1 : 0

  domain = digitalocean_domain.jerry_smith[0].name
  type   = "CNAME"
  name   = "protonmail._domainkey"
  value  = "protonmail.domainkey.dinou7fyzaz4gip3wxjftcttpe5zmfia4brvi46vremdv3unkowha.domains.proton.ch."
  ttl    = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "jerry_protonmail_dkim2_cname" {
  count = local.is_baseline ? 1 : 0

  domain = digitalocean_domain.jerry_smith[0].name
  type   = "CNAME"
  name   = "protonmail2._domainkey"
  value  = "protonmail2.domainkey.dinou7fyzaz4gip3wxjftcttpe5zmfia4brvi46vremdv3unkowha.domains.proton.ch."
  ttl    = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "jerry_protonmail_dkim3_cname" {
  count = local.is_baseline ? 1 : 0

  domain = digitalocean_domain.jerry_smith[0].name
  type   = "CNAME"
  name   = "protonmail3._domainkey"
  value  = "protonmail3.domainkey.dinou7fyzaz4gip3wxjftcttpe5zmfia4brvi46vremdv3unkowha.domains.proton.ch."
  ttl    = local.dns_ttl

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
  value  = module.web[0].public_ipv4_address
  ttl    = local.dns_ttl

  depends_on = [
    data.digitalocean_domain.grayhaven_systems,
    data.digitalocean_domain.jerry_smith,
  ]
}

resource "digitalocean_record" "web_www_cname" {
  for_each = local.is_environment ? local.environment_dns : {}

  domain = each.value.domain
  type   = "CNAME"
  name   = each.value.www_name
  value  = each.value.cname_target
  ttl    = local.dns_ttl

  depends_on = [
    data.digitalocean_domain.grayhaven_systems,
    data.digitalocean_domain.jerry_smith,
  ]
}

resource "digitalocean_record" "web_dev_cname" {
  for_each = local.is_environment ? local.environment_dns : {}

  domain = each.value.domain
  type   = "CNAME"
  name   = each.value.dev_name
  value  = each.value.cname_target
  ttl    = local.dns_ttl

  depends_on = [
    data.digitalocean_domain.grayhaven_systems,
    data.digitalocean_domain.jerry_smith,
  ]
}

resource "digitalocean_record" "grayhaven_droplet_a" {
  for_each = local.droplet_dns_records

  domain = each.value.domain
  type   = "A"
  name   = each.value.name
  value  = each.value.value
  ttl    = local.dns_ttl

  depends_on = [data.digitalocean_domain.grayhaven_systems]
}

resource "digitalocean_record" "grayhaven_bastion_a" {
  count = local.is_environment ? 1 : 0

  domain = local.client_domain
  type   = "A"
  name   = local.is_prod ? "bastion" : "bastion.staging"
  value  = module.bastion[0].public_ipv4_address
  ttl    = local.dns_ttl

  depends_on = [data.digitalocean_domain.grayhaven_systems]
}
