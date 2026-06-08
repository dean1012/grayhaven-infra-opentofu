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
    state_encryption_passphrase          = "offline-test-state-passphrase"
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
    condition     = digitalocean_domain.grayhaven_systems[0].name == "grayhavensystems.com" && digitalocean_domain.jerry_smith[0].name == "jerry-smith.net"
    error_message = "The baseline plan must include both managed DNS zones."
  }

  assert {
    condition     = digitalocean_vpc.baseline[0].name == "grayhaven-core-baseline-vpc"
    error_message = "The baseline plan must include the protected baseline VPC."
  }
}
