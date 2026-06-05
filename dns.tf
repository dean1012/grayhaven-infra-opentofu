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

resource "digitalocean_record" "grayhaven_mail_a" {
  count = local.is_baseline ? 1 : 0

  domain = digitalocean_domain.grayhaven_systems[0].name
  type   = "A"
  name   = "mail"
  value  = "199.188.205.246"
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
  value    = "mail.grayhavensystems.com."
  priority = 10
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
  value  = "v=spf1 +a +mx ip4:199.188.205.241 +ip4:199.188.205.246 ~all"
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
  value  = "v=DMARC1; p=quarantine; pct=100;"
  ttl    = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "grayhaven_dkim_txt" {
  count = local.is_baseline ? 1 : 0

  domain = digitalocean_domain.grayhaven_systems[0].name
  type   = "TXT"
  name   = "default._domainkey"
  value  = "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyTZ8ypaQ83IACu7K1g00Pe65ogpBPSWO+MrAFuP49cd5f0wpviEYsq5jGT1AHGrZzWLvY2dolo0mWvq4NzKAbThwLb3KwMjsnAr3cRvh1IgyexmW3Kx/iaag/E2SYHUfQj6I2qNYK21sgcw5atxPpOWbC8uU33rlCZ6c6v4H2wVZtR12QSRYgxfEL0E1o88MAr2FRaYEhm+hfeoA88ky96Q5MaIc8Bb7JBxIpTkrEqlsXlq4IEgXbzQhZsXpOSGYVsjYIznB8cYNcqfpj7Yay+56eTcMjU4rfic4pGaltiz0Bfr8Tfw7vKTONEoo5mVXD/S9p2BYrw32okCCzdpMAwIDAQAB;"
  ttl    = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "grayhaven_autodiscover_cname" {
  count = local.is_baseline ? 1 : 0

  domain = digitalocean_domain.grayhaven_systems[0].name
  type   = "CNAME"
  name   = "autodiscover"
  value  = "mail.grayhavensystems.com."
  ttl    = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "grayhaven_autoconfig_cname" {
  count = local.is_baseline ? 1 : 0

  domain = digitalocean_domain.grayhaven_systems[0].name
  type   = "CNAME"
  name   = "autoconfig"
  value  = "mail.grayhavensystems.com."
  ttl    = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "grayhaven_autodiscover_srv" {
  count = local.is_baseline ? 1 : 0

  domain   = digitalocean_domain.grayhaven_systems[0].name
  type     = "SRV"
  name     = "_autodiscover._tcp"
  value    = "cpanelemaildiscovery.cpanel.net."
  port     = 443
  priority = 0
  weight   = 0
  ttl      = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "jerry_mail_a" {
  count = local.is_baseline ? 1 : 0

  domain = digitalocean_domain.jerry_smith[0].name
  type   = "A"
  name   = "mail"
  value  = "199.188.205.246"
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
  value    = "mail.jerry-smith.net."
  priority = 10
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
  value  = "v=spf1 +a +mx ip4:199.188.205.241 +ip4:199.188.205.246 ~all"
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
  value  = "v=DMARC1; p=quarantine; pct=100;"
  ttl    = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "jerry_dkim_txt" {
  count = local.is_baseline ? 1 : 0

  domain = digitalocean_domain.jerry_smith[0].name
  type   = "TXT"
  name   = "default._domainkey"
  value  = "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyTZ8ypaQ83IACu7K1g00Pe65ogpBPSWO+MrAFuP49cd5f0wpviEYsq5jGT1AHGrZzWLvY2dolo0mWvq4NzKAbThwLb3KwMjsnAr3cRvh1IgyexmW3Kx/iaag/E2SYHUfQj6I2qNYK21sgcw5atxPpOWbC8uU33rlCZ6c6v4H2wVZtR12QSRYgxfEL0E1o88MAr2FRaYEhm+hfeoA88ky96Q5MaIc8Bb7JBxIpTkrEqlsXlq4IEgXbzQhZsXpOSGYVsjYIznB8cYNcqfpj7Yay+56eTcMjU4rfic4pGaltiz0Bfr8Tfw7vKTONEoo5mVXD/S9p2BYrw32okCCzdpMAwIDAQAB;"
  ttl    = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "jerry_autodiscover_cname" {
  count = local.is_baseline ? 1 : 0

  domain = digitalocean_domain.jerry_smith[0].name
  type   = "CNAME"
  name   = "autodiscover"
  value  = "mail.jerry-smith.net."
  ttl    = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "jerry_autoconfig_cname" {
  count = local.is_baseline ? 1 : 0

  domain = digitalocean_domain.jerry_smith[0].name
  type   = "CNAME"
  name   = "autoconfig"
  value  = "mail.jerry-smith.net."
  ttl    = local.dns_ttl

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_record" "jerry_autodiscover_srv" {
  count = local.is_baseline ? 1 : 0

  domain   = digitalocean_domain.jerry_smith[0].name
  type     = "SRV"
  name     = "_autodiscover._tcp"
  value    = "cpanelemaildiscovery.cpanel.net."
  port     = 443
  priority = 0
  weight   = 0
  ttl      = local.dns_ttl

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
