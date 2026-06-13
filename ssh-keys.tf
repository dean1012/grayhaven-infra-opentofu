locals {
  ssh_keys_policy_path = coalesce(var.grayhaven_test_ssh_keys_policy_path, "${local.policy_directory}/ssh-keys.yml")
  ssh_keys_policy      = yamldecode(file(local.ssh_keys_policy_path))
  admin_ssh_keys       = try(local.ssh_keys_policy.admin_ssh_keys, {})

  admin_ssh_key_fingerprints = local.is_environment ? [
    for key in sort(keys(data.digitalocean_ssh_key.admin)) : data.digitalocean_ssh_key.admin[key].fingerprint
  ] : []
}

resource "digitalocean_ssh_key" "admin" {
  for_each = local.is_baseline ? local.admin_ssh_keys : {}

  name       = each.value.title
  public_key = each.value.public_key
}

data "digitalocean_ssh_key" "admin" {
  for_each = local.is_environment ? local.admin_ssh_keys : {}

  name = each.value.title
}
