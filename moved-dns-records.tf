moved {
  from = digitalocean_record.baseline_protected["grayhaven_systems.caa_letsencrypt"]
  to   = digitalocean_record.baseline_protected_caa["grayhaven_systems.caa_letsencrypt"]
}

moved {
  from = digitalocean_record.baseline_protected["grayhaven_systems.caa_no_wildcards"]
  to   = digitalocean_record.baseline_protected_caa["grayhaven_systems.caa_no_wildcards"]
}

moved {
  from = digitalocean_record.baseline_protected["grayhaven_systems.mx_primary"]
  to   = digitalocean_record.baseline_protected_mx["grayhaven_systems.mx_primary"]
}

moved {
  from = digitalocean_record.baseline_protected["grayhaven_systems.mx_secondary"]
  to   = digitalocean_record.baseline_protected_mx["grayhaven_systems.mx_secondary"]
}

moved {
  from = digitalocean_record.baseline_protected["grayhaven_systems.spf_txt"]
  to   = digitalocean_record.baseline_protected_txt["grayhaven_systems.spf_txt"]
}

moved {
  from = digitalocean_record.baseline_protected["grayhaven_systems.protonmail_verification_txt"]
  to   = digitalocean_record.baseline_protected_txt["grayhaven_systems.protonmail_verification_txt"]
}

moved {
  from = digitalocean_record.baseline_protected["grayhaven_systems.dmarc_txt"]
  to   = digitalocean_record.baseline_protected_txt["grayhaven_systems.dmarc_txt"]
}

moved {
  from = digitalocean_record.baseline_protected["grayhaven_systems.protonmail_dkim_cname"]
  to   = digitalocean_record.baseline_protected_cname["grayhaven_systems.protonmail_dkim_cname"]
}

moved {
  from = digitalocean_record.baseline_protected["grayhaven_systems.protonmail_dkim2_cname"]
  to   = digitalocean_record.baseline_protected_cname["grayhaven_systems.protonmail_dkim2_cname"]
}

moved {
  from = digitalocean_record.baseline_protected["grayhaven_systems.protonmail_dkim3_cname"]
  to   = digitalocean_record.baseline_protected_cname["grayhaven_systems.protonmail_dkim3_cname"]
}

moved {
  from = digitalocean_record.baseline_protected["jerry_smith.caa_letsencrypt"]
  to   = digitalocean_record.baseline_protected_caa["jerry_smith.caa_letsencrypt"]
}

moved {
  from = digitalocean_record.baseline_protected["jerry_smith.caa_no_wildcards"]
  to   = digitalocean_record.baseline_protected_caa["jerry_smith.caa_no_wildcards"]
}

moved {
  from = digitalocean_record.baseline_protected["jerry_smith.mx_primary"]
  to   = digitalocean_record.baseline_protected_mx["jerry_smith.mx_primary"]
}

moved {
  from = digitalocean_record.baseline_protected["jerry_smith.mx_secondary"]
  to   = digitalocean_record.baseline_protected_mx["jerry_smith.mx_secondary"]
}

moved {
  from = digitalocean_record.baseline_protected["jerry_smith.spf_txt"]
  to   = digitalocean_record.baseline_protected_txt["jerry_smith.spf_txt"]
}

moved {
  from = digitalocean_record.baseline_protected["jerry_smith.protonmail_verification_txt"]
  to   = digitalocean_record.baseline_protected_txt["jerry_smith.protonmail_verification_txt"]
}

moved {
  from = digitalocean_record.baseline_protected["jerry_smith.dmarc_txt"]
  to   = digitalocean_record.baseline_protected_txt["jerry_smith.dmarc_txt"]
}

moved {
  from = digitalocean_record.baseline_protected["jerry_smith.protonmail_dkim_cname"]
  to   = digitalocean_record.baseline_protected_cname["jerry_smith.protonmail_dkim_cname"]
}

moved {
  from = digitalocean_record.baseline_protected["jerry_smith.protonmail_dkim2_cname"]
  to   = digitalocean_record.baseline_protected_cname["jerry_smith.protonmail_dkim2_cname"]
}

moved {
  from = digitalocean_record.baseline_protected["jerry_smith.protonmail_dkim3_cname"]
  to   = digitalocean_record.baseline_protected_cname["jerry_smith.protonmail_dkim3_cname"]
}
