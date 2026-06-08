# Grayhaven Infrastructure (OpenTofu)

[![CI](https://github.com/dean1012/grayhaven-infra-opentofu/actions/workflows/ci.yml/badge.svg)](https://github.com/dean1012/grayhaven-infra-opentofu/actions/workflows/ci.yml)

Infrastructure-as-code repository for Grayhaven Systems LLC using OpenTofu and
DigitalOcean.

This repository is public for transparency and operational demonstration. It
shows how Grayhaven Systems LLC manages its own infrastructure, but it does not
store client infrastructure, client credentials, private deployment data,
private SSH keys, secrets, generated state, or other private operational data.

## Table of Contents

- [Scope](#scope)
- [Requirements](#requirements)
- [Required Environment Variables](#required-environment-variables)
- [DigitalOcean Token Scope](#digitalocean-token-scope)
- [Deployment Quick Reference](#deployment-quick-reference)
- [Policy Files](#policy-files)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [License](#license)

## Scope

- Manage shared baseline resources and separate staging/production runtime
  environments.
- Provision DigitalOcean VPCs, droplets, hardware firewalls, load balancers,
  DNS records, and project assignments.
- Define DNS, firewall, and compute behavior through committed policy files.
- Bootstrap hosts into
  [`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
  for ongoing convergence.
- Read non-secret selectors from a local checkout of the private
  `grayhaven-vault` repository.
- Keep OpenTofu state encrypted locally.

This repository is not a general-purpose deployment template. Deploying similar
automation for another organization requires review and adaptation.

[Back to top](#grayhaven-infrastructure-opentofu)

## Requirements

- OpenTofu.
- DigitalOcean account.
- DigitalOcean API token scoped for this automation.
- SSH public key uploaded to DigitalOcean.
- Local checkout of the private `grayhaven-vault` repository.
- Ansible Vault password and deploy key material for bastion bootstrap.

[Back to top](#grayhaven-infrastructure-opentofu)

## Required Environment Variables

OpenTofu variables are supplied with `TF_VAR_*` environment variables.

```bash
export TF_VAR_state_encryption_passphrase='<state encryption passphrase>'
export TF_VAR_do_token='<scoped DigitalOcean OpenTofu token>'
export TF_VAR_grayhaven_vault_repo_url='git@github.com:dean1012/grayhaven-vault.git'
export TF_VAR_grayhaven_vault_checkout_path='/path/to/grayhaven-vault'
export TF_VAR_grayhaven_ansible_deploy_public_key='<public deploy/control key>'
export TF_VAR_grayhaven_ansible_deploy_private_key='<private deploy/control key>'
```

Use either one shared vault password variable:

```bash
export TF_VAR_grayhaven_vault_password='<Ansible Vault password>'
```

Or separate environment-specific vault password variables:

```bash
export TF_VAR_grayhaven_vault_password_staging='<staging Ansible Vault password>'
export TF_VAR_grayhaven_vault_password_prod='<production Ansible Vault password>'
```

If `grayhaven_vault_checkout_path` is omitted, OpenTofu expects a sibling
checkout at `../grayhaven-vault` relative to this repository.

The `grayhaven_config_repo_ref`, `grayhaven_infra_policy_repo_ref`, and
`grayhaven_certificate_environment` variables are testing-related
fresh-deployment controls. Changing them on an existing environment is
undefined operational behavior and is not recommended.

[Back to top](#grayhaven-infrastructure-opentofu)

## DigitalOcean Token Scope

The `TF_VAR_do_token` token should be tightly scoped.

| Resource Type | Permissions                         |
| ------------- | ----------------------------------- |
| actions       | read                                |
| certificate   | create, read, delete                |
| domain        | create, read, update, delete        |
| droplet       | create, read, update, delete, admin |
| firewall      | create, read, update, delete        |
| image         | read                                |
| load_balancer | create, read, update, delete        |
| monitoring    | create, read, update, delete        |
| project       | create, read, update, delete        |
| regions       | read                                |
| sizes         | read                                |
| snapshot      | read                                |
| ssh_key       | create, read, update, delete        |
| tag           | create, read, delete                |
| vpc           | create, read, update, delete        |

If DigitalOcean rejects an operation during validation or deployment, inspect
the denied resource/action and update the token scope deliberately.

[Back to top](#grayhaven-infrastructure-opentofu)

## Deployment Quick Reference

Select the target workspace and run `tofu apply`. For staging and production,
that single apply provisions DigitalOcean resources, renders cloud-init,
bootstraps hosts into
[`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible),
and starts full Ansible convergence from the active control bastion.

Apply the shared baseline before deploying an environment:

```bash
tofu workspace select baseline
tofu apply
```

Deploy staging:

```bash
tofu workspace select staging
tofu apply
```

Deploy production:

```bash
tofu workspace select prod
tofu apply
```

Production reads `main` from `grayhaven-vault`. Staging reads `staging`.

See [Workspace Operations](docs/workspaces.md) for safe planning, applying,
destroying, control-node changes, and TLS-mode changes.

[Back to top](#grayhaven-infrastructure-opentofu)

## Policy Files

Policy files are committed under `policy/`:

- `policy/compute.yml`: bastion/web instance definitions, active control
  bastion, and web TLS mode.
- `policy/firewall/staging.yml`: staging hardware firewall policy.
- `policy/firewall/prod.yml`: production hardware firewall policy.

`policy/compute.yml` uses stable instance keys such as `bastion-01` and
`web-01`. The declared bastion control node receives the easy `bastion.*` DNS
record and is the only bastion expected to run the scheduled Ansible runner.

Web TLS behavior is selected by `web.tls_mode`:

- `auto`: one web host uses host TLS; two or more web hosts use load balancer
  TLS.
- `load_balancer`: always use load balancer TLS.

Load balancer TLS uses HTTP-01 validation. The relevant web DNS records must
point at the load balancer during live certificate issuance.

[Back to top](#grayhaven-infrastructure-opentofu)

## Documentation

- [Workspace Operations](docs/workspaces.md)

[Back to top](#grayhaven-infrastructure-opentofu)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for validation commands and contribution
guidelines.

[Back to top](#grayhaven-infrastructure-opentofu)

## License

MIT

[Back to top](#grayhaven-infrastructure-opentofu)
