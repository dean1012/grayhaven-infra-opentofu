variables {
  state_encryption_passphrase_prod     = "offline-test-prod-state-passphrase"
  do_token                             = "offline-test-token"
  grayhaven_vault_checkout_path        = "/tmp/grayhaven-vault-offline-test"
  grayhaven_vault_password_prod        = "offline-test-prod-vault-password"
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
      ipv4_address         = "198.51.100.10"
      ipv4_address_private = "10.30.0.10"
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
      ip  = "198.51.100.20"
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
          certificate_environment: production
          discord_webhook: production
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
              outbound:
                - protocol: tcp
                  port_range: "443"
                  destination_addresses:
                    - 0.0.0.0/0
        EOT
      }
    }
  }
}

run "prod_committed_policy_plan" {
  command = plan

  plan_options {
    refresh = false
  }

  providers = {
    digitalocean = digitalocean
    external     = external
  }

  assert {
    condition     = output.workspace == "prod"
    error_message = "The committed production policy must plan in the prod workspace."
  }
}

run "prod_1x1_auto_host_plan" {
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
    condition     = output.workspace == "prod"
    error_message = "The production tests must run in the prod workspace."
  }

  assert {
    condition     = output.web_tls_mode == "host"
    error_message = "A 1/1 auto production policy must resolve to host TLS."
  }

  assert {
    condition     = length(output.bastion_public_ipv4_addresses) == 1 && length(output.web_public_ipv4_addresses) == 1
    error_message = "The 1/1 production policy must plan one bastion and one web host."
  }

  assert {
    condition     = output.control_bastion.key == "bastion-01"
    error_message = "The 1/1 production policy must keep bastion-01 as the control node."
  }

  assert {
    condition = (
      length(digitalocean_record.baseline_protected_a) +
      length(digitalocean_record.baseline_protected_cname) +
      length(digitalocean_record.baseline_protected_mx) +
      length(digitalocean_record.baseline_protected_txt) +
      length(digitalocean_record.baseline_protected_caa)
    ) == 0
    error_message = "Production must not own baseline shared or mail DNS records."
  }

  assert {
    condition = (
      length(digitalocean_record.baseline_a) +
      length(digitalocean_record.baseline_cname) +
      length(digitalocean_record.baseline_txt)
    ) == 0
    error_message = "Production must not own unprotected baseline DNS records."
  }

  assert {
    condition     = digitalocean_record.web_root_a["grayhaven_systems"].name == "@" && digitalocean_record.web_dev_cname["jerry_smith"].name == "dev"
    error_message = "Production must plan computed environment DNS records from DNS policy."
  }

  assert {
    condition     = length(output.admin_ssh_key_fingerprints) == 1 && output.admin_ssh_key_fingerprints[0] == "offline-admin-key-fingerprint"
    error_message = "Production droplets must receive admin SSH keys from policy lookup."
  }
}

run "prod_2x2_auto_load_balancer_plan" {
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
    error_message = "A 2/2 auto production policy must resolve to load-balancer TLS."
  }

  assert {
    condition     = length(output.bastion_public_ipv4_addresses) == 2 && length(output.web_public_ipv4_addresses) == 2
    error_message = "The 2/2 production policy must plan two bastions and two web hosts."
  }

  assert {
    condition     = output.control_bastion.key == "bastion-02"
    error_message = "The 2/2 production policy must move control to bastion-02."
  }

  assert {
    condition     = length(digitalocean_loadbalancer.web) == 1 && length(digitalocean_certificate.web_lb_production) == 1
    error_message = "A 2/2 production load-balancer plan must include a load balancer and production certificate."
  }

  assert {
    condition = jsonencode(output.web_certificate_domain_names) == jsonencode([
      "grayhavensystems.com",
      "www.grayhavensystems.com",
      "dev.grayhavensystems.com",
      "jerry-smith.net",
      "www.jerry-smith.net",
      "dev.jerry-smith.net"
    ])
    error_message = "Production load-balancer certificate names must keep the per-domain apex, www, dev order."
  }
}

run "prod_apex_only_dns_plan" {
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
    condition     = length(digitalocean_record.web_root_a) == 1 && digitalocean_record.web_root_a["grayhaven_systems"].name == "@"
    error_message = "Production apex DNS must be optional and independent from web aliases."
  }

  assert {
    condition     = length(digitalocean_record.web_www_cname) == 0 && length(digitalocean_record.web_dev_cname) == 0
    error_message = "Production must not plan www/dev aliases when environment.web_aliases is false."
  }

  assert {
    condition     = jsonencode(output.web_certificate_domain_names) == jsonencode(["grayhavensystems.com"])
    error_message = "Production apex-only DNS must request only the apex certificate name."
  }
}

run "prod_explicit_dns_record_plan" {
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
    error_message = "Production must plan explicit unprotected DNS records from environment DNS policy."
  }

  assert {
    condition = (
      digitalocean_record.environment_a["grayhaven_systems.infrastructure_notice_a"].type == "A" &&
      digitalocean_record.environment_cname["grayhaven_systems.infrastructure_notice_cname"].type == "CNAME" &&
      digitalocean_record.environment_txt["grayhaven_systems.infrastructure_notice_txt"].type == "TXT"
    )
    error_message = "Production environment DNS records must support A, CNAME, and TXT records."
  }

  assert {
    condition = (
      length(digitalocean_record.environment_protected_a) == 1 &&
      length(digitalocean_record.environment_protected_cname) == 1 &&
      length(digitalocean_record.environment_protected_txt) == 1
    )
    error_message = "Production must plan explicit protected DNS records from environment DNS policy."
  }
}

run "prod_environment_protected_mx_caa_rejected" {
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

run "prod_3x3_explicit_load_balancer_plan" {
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
    error_message = "A 3/3 explicit production policy must use load-balancer TLS."
  }

  assert {
    condition     = length(output.bastion_public_ipv4_addresses) == 3 && length(output.web_public_ipv4_addresses) == 3
    error_message = "The 3/3 production policy must plan three bastions and three web hosts."
  }

  assert {
    condition     = output.control_bastion.key == "bastion-03"
    error_message = "The 3/3 production policy must move control to bastion-03."
  }

  assert {
    condition     = length(digitalocean_loadbalancer.web) == 1 && length(digitalocean_certificate.web_lb_production) == 1
    error_message = "A 3/3 production load-balancer plan must include a load balancer and production certificate."
  }
}
