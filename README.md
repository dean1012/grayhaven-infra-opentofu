# Grayhaven Infrastructure (OpenTofu)

[![CI](https://github.com/dean1012/grayhaven-infra-opentofu/actions/workflows/ci.yml/badge.svg)](https://github.com/dean1012/grayhaven-infra-opentofu/actions/workflows/ci.yml)
[![OpenTofu Plan Tests](https://github.com/dean1012/grayhaven-infra-opentofu/actions/workflows/tofu-tests.yml/badge.svg)](https://github.com/dean1012/grayhaven-infra-opentofu/actions/workflows/tofu-tests.yml)

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
- [Environment Setup](#environment-setup)
- [DigitalOcean Token Scope](#digitalocean-token-scope)
- [Deployment Quick Reference](#deployment-quick-reference)
- [Offline Plan Tests](#offline-plan-tests)
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
- SSH admin public keys defined in `policy/ssh-keys.yml`.
- Local checkout of the private `grayhaven-vault` repository with the required
  environment refs fetched.
- Ansible Vault password and deploy key material for bastion bootstrap.

[Back to top](#grayhaven-infrastructure-opentofu)

## Required Environment Variables

OpenTofu variables are supplied with `TF_VAR_*` environment variables.

```bash
export TF_VAR_state_encryption_passphrase_baseline='<baseline state encryption passphrase>'
export TF_VAR_state_encryption_passphrase_staging='<staging state encryption passphrase>'
export TF_VAR_state_encryption_passphrase_prod='<production state encryption passphrase>'
export TF_VAR_do_token='<scoped DigitalOcean OpenTofu token>'
export TF_VAR_grayhaven_vault_repo_url='git@github.com:dean1012/grayhaven-vault.git'
export TF_VAR_grayhaven_vault_checkout_path='/path/to/grayhaven-vault'
export TF_VAR_grayhaven_ansible_deploy_public_key='<public deploy/control key>'
export TF_VAR_grayhaven_ansible_deploy_private_key='<private deploy/control key>'
export TF_VAR_grayhaven_vault_password_staging='<staging Ansible Vault password>'
export TF_VAR_grayhaven_vault_password_prod='<production Ansible Vault password>'
```

If `grayhaven_vault_checkout_path` is omitted, OpenTofu expects a sibling
checkout at `../grayhaven-vault` relative to this repository.

OpenTofu reads `config.yml` from the workspace-selected Git ref in the local
vault checkout, not from the checkout's current branch. Fetch the expected refs
before planning or applying:

```bash
git -C ../grayhaven-vault fetch origin main staging
```

The `grayhaven_config_repo_ref`, `grayhaven_infra_policy_repo_ref`, and
`grayhaven_certificate_environment` variables are testing-related
fresh-deployment controls. Changing them on an existing environment is
undefined operational behavior and is not recommended.

[Back to top](#grayhaven-infrastructure-opentofu)

## Environment Setup

Keep OpenTofu secrets out of the repository and shell history. A local shell
fragment is a convenient way to load the required variables without committing
them:

```bash
mkdir -p ~/.bashrc.d
install -m 0600 /dev/null ~/.bashrc.d/grayhaven-infra.sh
```

Edit `~/.bashrc.d/grayhaven-infra.sh` and add exports for the required
variables from [Required Environment Variables](#required-environment-variables).
After editing, source the shell configuration:

```bash
source ~/.bashrc
```

Validate that required secrets are defined without printing their values:

```bash
for var in \
  TF_VAR_state_encryption_passphrase_baseline \
  TF_VAR_state_encryption_passphrase_staging \
  TF_VAR_state_encryption_passphrase_prod \
  TF_VAR_do_token \
  TF_VAR_grayhaven_vault_repo_url \
  TF_VAR_grayhaven_vault_checkout_path \
  TF_VAR_grayhaven_ansible_deploy_public_key \
  TF_VAR_grayhaven_ansible_deploy_private_key \
  TF_VAR_grayhaven_vault_password_staging \
  TF_VAR_grayhaven_vault_password_prod
do
  if [ -n "${!var}" ]; then
    printf '%s=defined\n' "$var"
  else
    printf '%s=missing\n' "$var"
  fi
done
```

When an OpenTofu state passphrase rotation is active, also verify the matching
`TF_VAR_state_encryption_previous_passphrase_<workspace>` variable is defined
for the workspace being rotated.

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

Select the target workspace, review a plan, and apply only after the proposed
changes are understood. For staging and production, the approved apply is the
single command that carries the environment from infrastructure provisioning
through configuration convergence: it provisions DigitalOcean resources,
renders cloud-init, bootstraps hosts into
[`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible),
and starts full Ansible convergence from the active control bastion.

Apply the shared baseline before deploying an environment:

```bash
tofu workspace select baseline
tofu plan
tofu apply
```

Deploy staging:

```bash
tofu workspace select staging
tofu plan
tofu apply
```

Deploy production:

```bash
tofu workspace select prod
tofu plan
tofu apply
```

Production reads `main` from `grayhaven-vault`. Staging reads `staging`.
The local vault checkout does not need to be switched to either branch.

See [Workspace Operations](docs/workspaces.md) for safe planning, applying,
destroying, control-node changes, and TLS-mode changes.

[Back to top](#grayhaven-infrastructure-opentofu)

## Offline Plan Tests

CI runs offline `tofu test` coverage for the supported workspaces. These tests
use `command = plan`, mocked providers, and refresh-disabled plans so they can
validate deployment shape without DigitalOcean credentials, private vault
access, state files, or deployed resources.

The tests cover:

- baseline plan shape;
- baseline-owned protected shared DNS records;
- baseline-owned unprotected DNS records through a test-only policy fixture;
- environment-owned web DNS records without mail record ownership;
- static staging and production 1/1 bastion/web host TLS plans;
- static staging and production 2/2 auto load-balancer plans;
- static staging and production 3/3 explicit load-balancer plans.

Offline tests do not replace real `tofu plan`, real staging deployment, drift
checks, provider/API validation, or destroy safety validation. They are
regression tests for the deployment shapes this repository should be able to
plan, regardless of the currently committed operational compute policy.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the safe local validation workflow.

[Back to top](#grayhaven-infrastructure-opentofu)

## Policy Files

Policy files are committed under `policy/`:

- `policy/compute.yml`: bastion/web instance definitions, active control
  bastion, and web TLS mode.
- `policy/dns.yml`: managed DNS zones, baseline-owned DNS records, and domains
  that should receive environment web records.
- `policy/ssh-keys.yml`: admin SSH public keys managed by the baseline
  workspace and attached to all environment droplets.
- `policy/firewall/staging.yml`: staging hardware firewall policy.
- `policy/firewall/prod.yml`: production hardware firewall policy.

Names and DigitalOcean tags follow the conventions documented in
[Infrastructure Conventions](docs/conventions.md).

`policy/compute.yml` uses stable instance keys such as `bastion-01` and
`web-01`. The declared bastion control node receives the easy `bastion.*` DNS
record and is the only bastion expected to run the scheduled Ansible runner.

The DNS policy separates baseline and environment ownership. DNS zones and
shared records such as MX, SPF, DKIM, DMARC, and CAA records belong under
`protected_records` and are baseline resources with OpenTofu destroy
protection. Less critical baseline records can be placed under `records`; they
are managed by the baseline workspace but are not protected from destroy.
Staging and production own only environment web records for domains marked with
`environment_web: true`.

The admin SSH key policy uses stable internal keys under `admin_ssh_keys`.
Each entry has a `title`, which is also the DigitalOcean SSH key name, and a
`public_key`. Public SSH keys are not secret. Private SSH keys must never be
committed. Add or remove admin keys by updating `policy/ssh-keys.yml`, applying
the `baseline` workspace first, then reviewing staging or production plans so
droplets receive the intended key set.

When adding a new hosted domain, update `policy/dns.yml` here and then update
the `hosted_domains` data documented in
[`grayhaven-vault-example`](https://github.com/dean1012/grayhaven-vault-example).
This keeps DNS ownership and Ansible web-hosting configuration explicit.

Web TLS behavior is selected by `web.tls_mode`:

- `auto`: one web host uses host TLS; two or more web hosts use load balancer
  TLS.
- `load_balancer`: always use load balancer TLS.

Load balancer TLS uses HTTP-01 validation. The relevant web DNS records must
point at the load balancer during live certificate issuance.

The `grayhaven_test_compute_policy_path` variable exists only for offline plan
tests and disposable validation checkouts. Leave it unset for operational
deployment.

[Back to top](#grayhaven-infrastructure-opentofu)

## Documentation

- [Infrastructure Conventions](docs/conventions.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Workspace Operations](docs/workspaces.md)

[Back to top](#grayhaven-infrastructure-opentofu)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for validation commands and contribution
guidelines.

[Back to top](#grayhaven-infrastructure-opentofu)

## License

MIT

[Back to top](#grayhaven-infrastructure-opentofu)
