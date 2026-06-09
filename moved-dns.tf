# Temporary DNS state migration mappings from the pre-policy DNS resource
# addresses to the policy-driven resource addresses. Remove this file only
# after the baseline workspace has been applied once and no old DNS addresses
# remain in state.
moved {
  from = digitalocean_domain.grayhaven_systems[0]
  to   = digitalocean_domain.managed["grayhaven_systems"]
}

moved {
  from = digitalocean_domain.jerry_smith[0]
  to   = digitalocean_domain.managed["jerry_smith"]
}

moved {
  from = digitalocean_record.grayhaven_caa_letsencrypt[0]
  to   = digitalocean_record.baseline_protected["grayhaven_systems.caa_letsencrypt"]
}

moved {
  from = digitalocean_record.grayhaven_caa_no_wildcards[0]
  to   = digitalocean_record.baseline_protected["grayhaven_systems.caa_no_wildcards"]
}

moved {
  from = digitalocean_record.grayhaven_mx[0]
  to   = digitalocean_record.baseline_protected["grayhaven_systems.mx_primary"]
}

moved {
  from = digitalocean_record.grayhaven_mx_secondary[0]
  to   = digitalocean_record.baseline_protected["grayhaven_systems.mx_secondary"]
}

moved {
  from = digitalocean_record.grayhaven_spf_txt[0]
  to   = digitalocean_record.baseline_protected["grayhaven_systems.spf_txt"]
}

moved {
  from = digitalocean_record.grayhaven_protonmail_verification_txt[0]
  to   = digitalocean_record.baseline_protected["grayhaven_systems.protonmail_verification_txt"]
}

moved {
  from = digitalocean_record.grayhaven_dmarc_txt[0]
  to   = digitalocean_record.baseline_protected["grayhaven_systems.dmarc_txt"]
}

moved {
  from = digitalocean_record.grayhaven_protonmail_dkim_cname[0]
  to   = digitalocean_record.baseline_protected["grayhaven_systems.protonmail_dkim_cname"]
}

moved {
  from = digitalocean_record.grayhaven_protonmail_dkim2_cname[0]
  to   = digitalocean_record.baseline_protected["grayhaven_systems.protonmail_dkim2_cname"]
}

moved {
  from = digitalocean_record.grayhaven_protonmail_dkim3_cname[0]
  to   = digitalocean_record.baseline_protected["grayhaven_systems.protonmail_dkim3_cname"]
}

moved {
  from = digitalocean_record.jerry_caa_letsencrypt[0]
  to   = digitalocean_record.baseline_protected["jerry_smith.caa_letsencrypt"]
}

moved {
  from = digitalocean_record.jerry_caa_no_wildcards[0]
  to   = digitalocean_record.baseline_protected["jerry_smith.caa_no_wildcards"]
}

moved {
  from = digitalocean_record.jerry_mx[0]
  to   = digitalocean_record.baseline_protected["jerry_smith.mx_primary"]
}

moved {
  from = digitalocean_record.jerry_mx_secondary[0]
  to   = digitalocean_record.baseline_protected["jerry_smith.mx_secondary"]
}

moved {
  from = digitalocean_record.jerry_spf_txt[0]
  to   = digitalocean_record.baseline_protected["jerry_smith.spf_txt"]
}

moved {
  from = digitalocean_record.jerry_protonmail_verification_txt[0]
  to   = digitalocean_record.baseline_protected["jerry_smith.protonmail_verification_txt"]
}

moved {
  from = digitalocean_record.jerry_dmarc_txt[0]
  to   = digitalocean_record.baseline_protected["jerry_smith.dmarc_txt"]
}

moved {
  from = digitalocean_record.jerry_protonmail_dkim_cname[0]
  to   = digitalocean_record.baseline_protected["jerry_smith.protonmail_dkim_cname"]
}

moved {
  from = digitalocean_record.jerry_protonmail_dkim2_cname[0]
  to   = digitalocean_record.baseline_protected["jerry_smith.protonmail_dkim2_cname"]
}

moved {
  from = digitalocean_record.jerry_protonmail_dkim3_cname[0]
  to   = digitalocean_record.baseline_protected["jerry_smith.protonmail_dkim3_cname"]
}
