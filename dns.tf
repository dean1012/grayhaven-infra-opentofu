locals {
  dns_ttl = 300
}

###############################################################################
# grayhavensystems.com domain and DNS records
###############################################################################

resource "digitalocean_domain" "grayhaven_systems" {
  name = "grayhavensystems.com"
}

# A record for grayhavensystems.com pointing to the web server's reserved IP
resource "digitalocean_record" "grayhaven_root_a" {
  domain = digitalocean_domain.grayhaven_systems.name
  type   = "A"
  name   = "@"
  value  = module.web.ipv4_address
  ttl    = local.dns_ttl
}

# CNAME record for www.grayhavensystems.com pointing to grayhavensystems.com
resource "digitalocean_record" "grayhaven_www_cname" {
  domain = digitalocean_domain.grayhaven_systems.name
  type   = "CNAME"
  name   = "www"
  value  = "@"
  ttl    = local.dns_ttl
}

# A record for bastion.grayhavensystems.com pointing to the bastion host's reserved IP
resource "digitalocean_record" "grayhaven_bastion_a" {
  domain = digitalocean_domain.grayhaven_systems.name
  type   = "A"
  name   = "bastion"
  value  = module.bastion.ipv4_address
  ttl    = local.dns_ttl
}

# A record for mail.grayhavensystems.com pointing to the mail server's public IP address.
# Note: this points to an external server not managed by us.
resource "digitalocean_record" "grayhaven_mail_a" {
  domain = digitalocean_domain.grayhaven_systems.name
  type   = "A"
  name   = "mail"
  value  = "199.188.205.246"
  ttl    = local.dns_ttl
}

# MX record for grayhavensystems.com pointing to mail.grayhavensystems.com
resource "digitalocean_record" "grayhaven_mx" {
  domain   = digitalocean_domain.grayhaven_systems.name
  type     = "MX"
  name     = "@"
  value    = "mail.grayhavensystems.com."
  priority = 10
  ttl      = local.dns_ttl
}

# SPF record for grayhavensystems.com specifying authorized mail servers
resource "digitalocean_record" "grayhaven_spf_txt" {
  domain = digitalocean_domain.grayhaven_systems.name
  type   = "TXT"
  name   = "@"
  value  = "v=spf1 +a +mx ip4:199.188.205.241 +ip4:199.188.205.246 ~all"
  ttl    = local.dns_ttl
}

# DMARC record for grayhavensystems.com specifying email handling policy
# quarantine means suspicious emails will be marked as spam but still delivered
resource "digitalocean_record" "grayhaven_dmarc_txt" {
  domain = digitalocean_domain.grayhaven_systems.name
  type   = "TXT"
  name   = "_dmarc"
  value  = "v=DMARC1; p=quarantine; pct=100;"
  ttl    = local.dns_ttl
}

# DKIM record for grayhavensystems.com specifying the public key for email signing
resource "digitalocean_record" "grayhaven_dkim_txt" {
  domain = digitalocean_domain.grayhaven_systems.name
  type   = "TXT"
  name   = "default._domainkey"
  value  = "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyTZ8ypaQ83IACu7K1g00Pe65ogpBPSWO+MrAFuP49cd5f0wpviEYsq5jGT1AHGrZzWLvY2dolo0mWvq4NzKAbThwLb3KwMjsnAr3cRvh1IgyexmW3Kx/iaag/E2SYHUfQj6I2qNYK21sgcw5atxPpOWbC8uU33rlCZ6c6v4H2wVZtR12QSRYgxfEL0E1o88MAr2FRaYEhm+hfeoA88ky96Q5MaIc8Bb7JBxIpTkrEqlsXlq4IEgXbzQhZsXpOSGYVsjYIznB8cYNcqfpj7Yay+56eTcMjU4rfic4pGaltiz0Bfr8Tfw7vKTONEoo5mVXD/S9p2BYrw32okCCzdpMAwIDAQAB;"
  ttl    = local.dns_ttl
}

# CNAME record for autodiscover.grayhavensystems.com pointing to mail.grayhavensystems.com
# Automatically provides email client configuration settings
resource "digitalocean_record" "grayhaven_autodiscover_cname" {
  domain = digitalocean_domain.grayhaven_systems.name
  type   = "CNAME"
  name   = "autodiscover"
  value  = "mail.grayhavensystems.com."
  ttl    = local.dns_ttl
}

# CNAME record for autoconfig.grayhavensystems.com pointing to mail.grayhavensystems.com
# Automatically provides email client configuration settings
resource "digitalocean_record" "grayhaven_autoconfig_cname" {
  domain = digitalocean_domain.grayhaven_systems.name
  type   = "CNAME"
  name   = "autoconfig"
  value  = "mail.grayhavensystems.com."
  ttl    = local.dns_ttl
}

# SRV record for autodiscover.grayhavensystems.com pointing to cpanel's email discovery service
resource "digitalocean_record" "grayhaven_autodiscover_srv" {
  domain   = digitalocean_domain.grayhaven_systems.name
  type     = "SRV"
  name     = "_autodiscover._tcp"
  value    = "cpanelemaildiscovery.cpanel.net."
  port     = 443
  priority = 0
  weight   = 0
  ttl      = local.dns_ttl
}

###############################################################################
# jerry-smith.net domain and DNS records
###############################################################################

resource "digitalocean_domain" "jerry_smith" {
  name = "jerry-smith.net"
}

# A record for jerry-smith.net pointing to the web server's reserved IP
resource "digitalocean_record" "jerry_root_a" {
  domain = digitalocean_domain.jerry_smith.name
  type   = "A"
  name   = "@"
  value  = module.web.ipv4_address
  ttl    = local.dns_ttl
}

# CNAME record for www.jerry-smith.net pointing to jerry-smith.net
resource "digitalocean_record" "jerry_www_cname" {
  domain = digitalocean_domain.jerry_smith.name
  type   = "CNAME"
  name   = "www"
  value  = "@"
  ttl    = local.dns_ttl
}

# A record for mail.jerry-smith.net pointing to the mail server's public IP address.
# Note: this points to an external server not managed by us.
resource "digitalocean_record" "jerry_mail_a" {
  domain = digitalocean_domain.jerry_smith.name
  type   = "A"
  name   = "mail"
  value  = "199.188.205.246"
  ttl    = local.dns_ttl
}

# MX record for jerry-smith.net pointing to mail.jerry-smith.net
resource "digitalocean_record" "jerry_mx" {
  domain   = digitalocean_domain.jerry_smith.name
  type     = "MX"
  name     = "@"
  value    = "mail.jerry-smith.net."
  priority = 10
  ttl      = local.dns_ttl
}

# SPF record for jerry-smith.net specifying authorized mail servers
resource "digitalocean_record" "jerry_spf_txt" {
  domain = digitalocean_domain.jerry_smith.name
  type   = "TXT"
  name   = "@"
  value  = "v=spf1 +a +mx ip4:199.188.205.241 +ip4:199.188.205.246 ~all"
  ttl    = local.dns_ttl
}

# DMARC record for jerry-smith.net specifying email handling policy
# quarantine means suspicious emails will be marked as spam but still delivered
resource "digitalocean_record" "jerry_dmarc_txt" {
  domain = digitalocean_domain.jerry_smith.name
  type   = "TXT"
  name   = "_dmarc"
  value  = "v=DMARC1; p=quarantine; pct=100;"
  ttl    = local.dns_ttl
}

# DKIM record for jerry-smith.net specifying the public key for email signing
resource "digitalocean_record" "jerry_dkim_txt" {
  domain = digitalocean_domain.jerry_smith.name
  type   = "TXT"
  name   = "default._domainkey"
  value  = "v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAyTZ8ypaQ83IACu7K1g00Pe65ogpBPSWO+MrAFuP49cd5f0wpviEYsq5jGT1AHGrZzWLvY2dolo0mWvq4NzKAbThwLb3KwMjsnAr3cRvh1IgyexmW3Kx/iaag/E2SYHUfQj6I2qNYK21sgcw5atxPpOWbC8uU33rlCZ6c6v4H2wVZtR12QSRYgxfEL0E1o88MAr2FRaYEhm+hfeoA88ky96Q5MaIc8Bb7JBxIpTkrEqlsXlq4IEgXbzQhZsXpOSGYVsjYIznB8cYNcqfpj7Yay+56eTcMjU4rfic4pGaltiz0Bfr8Tfw7vKTONEoo5mVXD/S9p2BYrw32okCCzdpMAwIDAQAB;"
  ttl    = local.dns_ttl
}

# CNAME record for autodiscover.jerry-smith.net pointing to mail.jerry-smith.net
# Automatically provides email client configuration settings
resource "digitalocean_record" "jerry_autodiscover_cname" {
  domain = digitalocean_domain.jerry_smith.name
  type   = "CNAME"
  name   = "autodiscover"
  value  = "mail.jerry-smith.net."
  ttl    = local.dns_ttl
}

# CNAME record for autoconfig.jerry-smith.net pointing to mail.jerry-smith.net
# Automatically provides email client configuration settings
resource "digitalocean_record" "jerry_autoconfig_cname" {
  domain = digitalocean_domain.jerry_smith.name
  type   = "CNAME"
  name   = "autoconfig"
  value  = "mail.jerry-smith.net."
  ttl    = local.dns_ttl
}

# SRV record for autodiscover.jerry-smith.net pointing to cpanel's email discovery service
resource "digitalocean_record" "jerry_autodiscover_srv" {
  domain   = digitalocean_domain.jerry_smith.name
  type     = "SRV"
  name     = "_autodiscover._tcp"
  value    = "cpanelemaildiscovery.cpanel.net."
  port     = 443
  priority = 0
  weight   = 0
  ttl      = local.dns_ttl
}
