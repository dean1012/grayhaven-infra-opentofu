variables {
  state_encryption_passphrase_staging  = "offline-test-staging-state-passphrase"
  do_token                             = "offline-test-token"
  grayhaven_vault_checkout_path        = "/tmp/grayhaven-vault-offline-test"
  grayhaven_vault_password_staging     = "offline-test-staging-vault-password"
  grayhaven_ansible_deploy_public_key  = "ssh-ed25519 AAAAoffline offline@example"
  grayhaven_ansible_deploy_private_key = <<-EOT
    -----BEGIN OPENSSH PRIVATE KEY-----
    offline-test-private-key
    -----END OPENSSH PRIVATE KEY-----
  EOT
}

mock_provider "digitalocean" {
  mock_data "digitalocean_ssh_key" {
    defaults = {
      fingerprint = "offline-admin-key-fingerprint"
      id          = 1
      public_key  = "ssh-ed25519 AAAAoffline-admin admin@example"
    }
  }

  mock_data "digitalocean_domain" {
    defaults = {
      id = "domain-id"
    }
  }

  mock_data "digitalocean_project" {
    defaults = {
      id = "project-id"
    }
  }

  mock_resource "digitalocean_certificate" {
    defaults = {
      id   = "certificate-id"
      uuid = "certificate-uuid"
    }
  }

  mock_resource "digitalocean_droplet" {
    defaults = {
      id                   = 1
      urn                  = "do:droplet:droplet-id"
      ipv4_address         = "203.0.113.10"
      ipv4_address_private = "10.20.0.10"
    }
  }

  mock_resource "digitalocean_firewall" {
    defaults = {
      id = "firewall-id"
    }
  }

  mock_resource "digitalocean_loadbalancer" {
    defaults = {
      id  = "loadbalancer-id"
      ip  = "203.0.113.20"
      urn = "do:loadbalancer:loadbalancer-id"
    }
  }

  mock_resource "digitalocean_project_resources" {
    defaults = {
      id = "project-resources-id"
    }
  }

  mock_resource "digitalocean_record" {
    defaults = {
      id = "record-id"
    }
  }

  mock_resource "digitalocean_tag" {
    defaults = {
      id = "tag-id"
    }
  }

  mock_resource "digitalocean_vpc" {
    defaults = {
      id  = "vpc-id"
      urn = "do:vpc:vpc-id"
    }
  }
}

mock_provider "external" {
  mock_data "external" {
    defaults = {
      result = {
        config_yml   = <<-EOT
          certificate_environment: staging
          discord_webhook: testing
          backup:
            repositories:
              local:
                repository_path: /var/backups/restic
                homedir_archive_path: /var/backups/deleted-homedir-archives
            schedule: daily
            retention:
              keep_daily: 7
            include:
              - /home
              - /var/log
            exclude: []
        EOT
        firewall_yml = <<-EOT
          firewalls:
            bastion:
              inbound:
                - protocol: tcp
                  port_range: "22"
                  source_addresses:
                    - 0.0.0.0/0
              outbound:
                - protocol: tcp
                  port_range: "22"
                  destination_tags:
                    - bastion
                    - web
            web:
              inbound:
                - protocol: tcp
                  port_range: "22"
                  source_tags:
                    - bastion
                - protocol: tcp
                  port_range: "80"
                  source_addresses:
                    - 0.0.0.0/0
                - protocol: tcp
                  port_range: "443"
                  source_addresses:
                    - 0.0.0.0/0
              outbound:
                - protocol: tcp
                  port_range: "80"
                  destination_addresses:
                    - 0.0.0.0/0
                - protocol: tcp
                  port_range: "443"
                  destination_addresses:
                    - 0.0.0.0/0
        EOT
      }
    }
  }
}

run "staging_committed_policy_plan" {
  command = plan

  plan_options {
    refresh = false
  }

  providers = {
    digitalocean = digitalocean
    external     = external
  }

  assert {
    condition     = output.workspace == "staging"
    error_message = "The committed staging policy must plan in the staging workspace."
  }
}

run "staging_1x1_auto_host_plan" {
  command = plan

  plan_options {
    refresh = false
  }

  providers = {
    digitalocean = digitalocean
    external     = external
  }

  variables {
    grayhaven_test_compute_policy_path = "tests/fixtures/compute-1x1-auto.yml"
  }

  assert {
    condition     = output.workspace == "staging"
    error_message = "The staging tests must run in the staging workspace."
  }

  assert {
    condition     = output.web_tls_mode == "host"
    error_message = "A 1/1 auto staging policy must resolve to host TLS."
  }

  assert {
    condition     = length(output.bastion_public_ipv4_addresses) == 1 && length(output.web_public_ipv4_addresses) == 1
    error_message = "The 1/1 staging policy must plan one bastion and one web host."
  }

  assert {
    condition     = output.control_bastion.key == "bastion-01"
    error_message = "The 1/1 staging policy must keep bastion-01 as the control node."
  }

  assert {
    condition = (
      length(digitalocean_record.baseline_protected_a) +
      length(digitalocean_record.baseline_protected_cname) +
      length(digitalocean_record.baseline_protected_mx) +
      length(digitalocean_record.baseline_protected_txt) +
      length(digitalocean_record.baseline_protected_caa)
    ) == 0
    error_message = "Staging must not own baseline shared or mail DNS records."
  }

  assert {
    condition = (
      length(digitalocean_record.baseline_a) +
      length(digitalocean_record.baseline_cname) +
      length(digitalocean_record.baseline_txt)
    ) == 0
    error_message = "Staging must not own unprotected baseline DNS records."
  }

  assert {
    condition     = digitalocean_record.web_root_a["grayhaven_systems"].name == "staging" && digitalocean_record.web_dev_cname["jerry_smith"].name == "dev.staging"
    error_message = "Staging must plan computed environment DNS records from DNS policy."
  }

  assert {
    condition     = length(output.admin_ssh_key_fingerprints) == 1 && output.admin_ssh_key_fingerprints[0] == "offline-admin-key-fingerprint"
    error_message = "Staging droplets must receive admin SSH keys from policy lookup."
  }
}

run "staging_2x2_auto_load_balancer_plan" {
  command = plan

  plan_options {
    refresh = false
  }

  providers = {
    digitalocean = digitalocean
    external     = external
  }

  variables {
    grayhaven_test_compute_policy_path = "tests/fixtures/compute-2x2-auto.yml"
  }

  assert {
    condition     = output.web_tls_mode == "load_balancer"
    error_message = "A 2/2 auto staging policy must resolve to load-balancer TLS."
  }

  assert {
    condition     = length(output.bastion_public_ipv4_addresses) == 2 && length(output.web_public_ipv4_addresses) == 2
    error_message = "The 2/2 staging policy must plan two bastions and two web hosts."
  }

  assert {
    condition     = output.control_bastion.key == "bastion-02"
    error_message = "The 2/2 staging policy must move control to bastion-02."
  }

  assert {
    condition     = length(digitalocean_loadbalancer.web) == 1 && length(digitalocean_certificate.web_lb_staging) == 1
    error_message = "A 2/2 staging load-balancer plan must include a load balancer and staging certificate."
  }

  assert {
    condition = (
      length([
        for rule in output.web_firewall_inbound_rules :
        rule if rule.protocol == "tcp" && rule.port_range == "80"
      ]) == 1 &&
      alltrue([
        for rule in output.web_firewall_inbound_rules :
        length(rule.source_load_balancer_uids) == 1
        if rule.protocol == "tcp" && rule.port_range == "80"
      ])
    )
    error_message = "Staging load-balancer TLS must restrict web HTTP origin traffic to the load balancer."
  }

  assert {
    condition = !contains([
      for rule in output.web_firewall_inbound_rules :
      rule.port_range
      if rule.protocol == "tcp"
    ], "443")
    error_message = "Staging load-balancer TLS must not expose direct web HTTPS origin traffic."
  }

  assert {
    condition = jsonencode(output.web_certificate_domain_names) == jsonencode([
      "staging.grayhavensystems.com",
      "www.staging.grayhavensystems.com",
      "dev.staging.grayhavensystems.com",
      "staging.jerry-smith.net",
      "www.staging.jerry-smith.net",
      "dev.staging.jerry-smith.net"
    ])
    error_message = "Staging load-balancer certificate names must keep the per-domain apex, www, dev order."
  }
}

run "staging_apex_only_dns_plan" {
  command = plan

  plan_options {
    refresh = false
  }

  providers = {
    digitalocean = digitalocean
    external     = external
  }

  variables {
    grayhaven_test_compute_policy_path = "tests/fixtures/compute-1x1-auto.yml"
    grayhaven_test_dns_policy_path     = "tests/fixtures/dns-with-apex-only-environment.yml"
  }

  assert {
    condition     = length(digitalocean_record.web_root_a) == 1 && digitalocean_record.web_root_a["grayhaven_systems"].name == "staging"
    error_message = "Staging apex DNS must be optional and independent from web aliases."
  }

  assert {
    condition     = length(digitalocean_record.web_www_cname) == 0 && length(digitalocean_record.web_dev_cname) == 0
    error_message = "Staging must not plan www/dev aliases when environment.web_aliases is false."
  }

  assert {
    condition     = jsonencode(output.web_certificate_domain_names) == jsonencode(["staging.grayhavensystems.com"])
    error_message = "Staging apex-only DNS must request only the apex certificate name."
  }
}

run "staging_web_aliases_require_apex" {
  command = plan

  plan_options {
    refresh = false
  }

  providers = {
    digitalocean = digitalocean
    external     = external
  }

  variables {
    grayhaven_test_compute_policy_path = "tests/fixtures/compute-1x1-auto.yml"
    grayhaven_test_dns_policy_path     = "tests/fixtures/dns-with-invalid-environment-aliases.yml"
  }

  expect_failures = [
    terraform_data.dns_policy_guard,
  ]
}

run "staging_explicit_dns_record_plan" {
  command = plan

  plan_options {
    refresh = false
  }

  providers = {
    digitalocean = digitalocean
    external     = external
  }

  variables {
    grayhaven_test_compute_policy_path = "tests/fixtures/compute-1x1-auto.yml"
    grayhaven_test_dns_policy_path     = "tests/fixtures/dns-with-environment-records.yml"
  }

  assert {
    condition = (
      length(digitalocean_record.environment_a) +
      length(digitalocean_record.environment_cname) +
      length(digitalocean_record.environment_txt)
    ) == 3
    error_message = "Staging must plan explicit unprotected DNS records from environment DNS policy."
  }

  assert {
    condition = (
      digitalocean_record.environment_a["grayhaven_systems.infrastructure_notice_a"].type == "A" &&
      digitalocean_record.environment_cname["grayhaven_systems.infrastructure_notice_cname"].type == "CNAME" &&
      digitalocean_record.environment_txt["grayhaven_systems.infrastructure_notice_txt"].type == "TXT"
    )
    error_message = "Staging environment DNS records must support A, CNAME, and TXT records."
  }

  assert {
    condition = (
      length(digitalocean_record.environment_protected_a) == 1 &&
      length(digitalocean_record.environment_protected_cname) == 1 &&
      length(digitalocean_record.environment_protected_txt) == 1
    )
    error_message = "Staging must plan explicit protected DNS records from environment DNS policy."
  }
}

run "staging_environment_protected_mx_caa_rejected" {
  command = plan

  plan_options {
    refresh = false
  }

  providers = {
    digitalocean = digitalocean
    external     = external
  }

  variables {
    grayhaven_test_compute_policy_path = "tests/fixtures/compute-1x1-auto.yml"
    grayhaven_test_dns_policy_path     = "tests/fixtures/dns-with-environment-protected-mx-caa.yml"
  }

  expect_failures = [
    terraform_data.dns_policy_guard,
  ]
}

run "staging_3x3_explicit_load_balancer_plan" {
  command = plan

  plan_options {
    refresh = false
  }

  providers = {
    digitalocean = digitalocean
    external     = external
  }

  variables {
    grayhaven_test_compute_policy_path = "tests/fixtures/compute-3x3-load-balancer.yml"
  }

  assert {
    condition     = output.web_tls_mode == "load_balancer"
    error_message = "A 3/3 explicit staging policy must use load-balancer TLS."
  }

  assert {
    condition     = length(output.bastion_public_ipv4_addresses) == 3 && length(output.web_public_ipv4_addresses) == 3
    error_message = "The 3/3 staging policy must plan three bastions and three web hosts."
  }

  assert {
    condition     = output.control_bastion.key == "bastion-03"
    error_message = "The 3/3 staging policy must move control to bastion-03."
  }

  assert {
    condition     = length(digitalocean_loadbalancer.web) == 1 && length(digitalocean_certificate.web_lb_staging) == 1
    error_message = "A 3/3 staging load-balancer plan must include a load balancer and staging certificate."
  }
}
