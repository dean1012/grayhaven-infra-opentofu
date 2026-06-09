mock_provider "digitalocean" {
  mock_resource "digitalocean_domain" {
    defaults = {
      id = "domain-id"
    }
  }

  mock_resource "digitalocean_project" {
    defaults = {
      id = "project-id"
    }
  }

  mock_resource "digitalocean_record" {
    defaults = {
      id = "record-id"
    }
  }

  mock_resource "digitalocean_vpc" {
    defaults = {
      id  = "vpc-id"
      urn = "do:vpc:vpc-id"
    }
  }
}

run "baseline_plan" {
  command = plan

  plan_options {
    refresh = false
  }

  providers = {
    digitalocean = digitalocean
  }

  variables {
    state_encryption_passphrase_baseline = "offline-test-baseline-state-passphrase"
    do_token                             = "offline-test-token"
    grayhaven_ansible_deploy_public_key  = "ssh-ed25519 AAAAoffline offline@example"
    grayhaven_ansible_deploy_private_key = <<-EOT
      -----BEGIN OPENSSH PRIVATE KEY-----
      offline-test-private-key
      -----END OPENSSH PRIVATE KEY-----
    EOT
  }

  assert {
    condition     = output.workspace == "baseline"
    error_message = "The baseline test must run in the baseline workspace."
  }

  assert {
    condition     = digitalocean_project.grayhaven[0].name == "grayhaven"
    error_message = "The baseline plan must include the shared DigitalOcean project."
  }

  assert {
    condition     = digitalocean_domain.managed["grayhaven_systems"].name == "grayhavensystems.com" && digitalocean_domain.managed["jerry_smith"].name == "jerry-smith.net"
    error_message = "The baseline plan must include both managed DNS zones."
  }

  assert {
    condition     = length(digitalocean_record.baseline_protected) == 20
    error_message = "The baseline plan must include all protected shared DNS records."
  }

  assert {
    condition     = length(digitalocean_record.baseline) == 0
    error_message = "The operational DNS policy should not plan unprotected baseline records until they are explicitly added."
  }

  assert {
    condition     = digitalocean_record.baseline_protected["grayhaven_systems.mx_primary"].type == "MX" && digitalocean_record.baseline_protected["jerry_smith.mx_primary"].type == "MX"
    error_message = "The baseline plan must retain mail DNS records under baseline ownership."
  }

  assert {
    condition     = digitalocean_vpc.baseline[0].name == "grayhaven-core-baseline-vpc"
    error_message = "The baseline plan must include the protected baseline VPC."
  }

  assert {
    condition     = digitalocean_ssh_key.admin["jsmith"].name == "jsmith@grayhavensystems.com"
    error_message = "The baseline plan must manage the configured admin SSH key."
  }
}

run "baseline_unprotected_dns_record_plan" {
  command = plan

  plan_options {
    refresh = false
  }

  providers = {
    digitalocean = digitalocean
  }

  variables {
    state_encryption_passphrase_baseline = "offline-test-baseline-state-passphrase"
    do_token                             = "offline-test-token"
    grayhaven_ansible_deploy_public_key  = "ssh-ed25519 AAAAoffline offline@example"
    grayhaven_ansible_deploy_private_key = <<-EOT
      -----BEGIN OPENSSH PRIVATE KEY-----
      offline-test-private-key
      -----END OPENSSH PRIVATE KEY-----
    EOT
    grayhaven_test_dns_policy_path       = "tests/fixtures/dns-with-unprotected-records.yml"
  }

  assert {
    condition     = length(digitalocean_record.baseline) == 1
    error_message = "The baseline test fixture must plan unprotected DNS records."
  }

  assert {
    condition     = digitalocean_record.baseline["grayhaven_systems.infrastructure_notice_txt"].type == "TXT"
    error_message = "The unprotected DNS record collection must preserve record attributes."
  }

  assert {
    condition     = length(digitalocean_record.baseline_protected) == 2
    error_message = "The baseline test fixture must still plan protected DNS records separately."
  }
}
