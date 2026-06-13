# Safety

This document describes safety boundaries for Grayhaven OpenTofu operations.

## Table of Contents

- [Baseline Safety](#baseline-safety)
- [Sensitive Output](#sensitive-output)
- [Secret Rotation](#secret-rotation)
- [State Safety](#state-safety)

## Baseline Safety

Do not destroy the `baseline` workspace. Baseline manages shared resources that
staging and production depend on, including DNS zones, mail records, CAA
records, admin SSH keys, the shared DigitalOcean project, and the default
baseline VPC.

Baseline resources are configured with OpenTofu destroy protection so
accidental baseline destroy attempts fail before removing shared resources.
Operators should still treat baseline destruction as out of bounds.

[Back to top](#safety)

## Sensitive Output

Keep terminal output private when plans may contain sensitive values. Do not
commit generated state, plan files, local environment files, or command output
that includes secrets.

Recommended handling:

- Keep OpenTofu environment variables out of shell history.
- Store local environment fragments outside the repository.
- Avoid sharing raw `tofu plan` or `tofu apply` output without reviewing it
  first.
- Keep private keys, Ansible Vault passphrases, DigitalOcean tokens, and state
  encryption passphrases out of issue comments, pull requests, and commit
  history.

[Back to top](#safety)

## Secret Rotation

Rotate secrets deliberately, one workspace or secret class at a time. Before
any rotation, confirm no other OpenTofu run or Ansible maintenance playbook is
active, back up local encrypted state, and keep all terminal output private.

### OpenTofu State Encryption Passphrases

State encryption passphrases are workspace-specific:

- `TF_VAR_state_encryption_passphrase_baseline`
- `TF_VAR_state_encryption_passphrase_staging`
- `TF_VAR_state_encryption_passphrase_prod`

To rotate one workspace state passphrase:

1. Back up the target workspace state and keep the backup private.
2. Export the old passphrase as the matching previous-passphrase variable:
   `TF_VAR_state_encryption_previous_passphrase_<workspace>`.
3. Export the new passphrase as
   `TF_VAR_state_encryption_passphrase_<workspace>`.
4. Select the target workspace.
5. Run `tofu plan` and confirm OpenTofu can read the existing state through
   the fallback method.
6. Run `tofu apply` so OpenTofu writes state with the new passphrase.
7. Unset and remove the previous-passphrase variable from the local shell
   configuration.
8. Run `tofu plan` again with only the new passphrase defined.

Do not remove or unset the previous passphrase until the apply has completed
and a follow-up plan succeeds with only the new passphrase.

### Ansible Vault Passphrases

Fresh bastion bootstrap receives the Ansible Vault password from:

- `TF_VAR_grayhaven_vault_password_staging`
- `TF_VAR_grayhaven_vault_password_prod`

When rotating an Ansible Vault passphrase, update the matching OpenTofu
environment variable for future deployments. The encrypted vault files are not
stored in this repository; rekey them by following the vault procedures
documented in
[`grayhaven-vault-example`](https://github.com/dean1012/grayhaven-vault-example).

For already deployed bastions, rotate the persisted password with
[`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
`playbooks/rotate-vault-password.yml`, then verify a manual runner invocation
can decrypt the vault after the rotation.

### DigitalOcean API Token

Create a replacement token with the documented scope, update
`TF_VAR_do_token`, then run a read-only `tofu plan` in `baseline`, `staging`,
and `prod` as applicable. Revoke the old token only after the new token can
plan the required workspaces.

### Deploy And Control Key Material

The deploy/control key is supplied to fresh droplets through
`TF_VAR_grayhaven_ansible_deploy_public_key` and
`TF_VAR_grayhaven_ansible_deploy_private_key`. For deployed bastions, rotate
the persisted key with
[`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
`playbooks/rotate-vault-deploy-key.yml`, then update the OpenTofu variables so
future droplets receive the new key during bootstrap.

### Admin SSH Keys

Admin SSH public keys are managed in `policy/<workspace>/ssh-keys.yml`. Update
`policy/baseline/ssh-keys.yml` first, update the environment policy files that
should attach the key to droplets, then update the private vault repository as
appropriate for users or automation keys by following
[`grayhaven-vault-example`](https://github.com/dean1012/grayhaven-vault-example).

[Back to top](#safety)

## State Safety

State is encrypted locally through workspace-specific OpenTofu state
encryption passphrases. Keep state backups private and do not commit them.

Offline `tofu test` validation should run from a temporary state-free copy, not
from the operational checkout used for real plan/apply work. The tests create
temporary local workspaces with mocked providers and do not replace live
workspace planning, drift review, staging deployment, or destroy procedures.

Recommended state handling:

- Keep state encryption passphrases out of shell history and committed files.
- Keep `terraform.tfstate*`, `terraform.tfstate.d/`, `.state-backups/`, and
  plan files private.
- Back up local state before large refactors or provider upgrades.
- Review plans before applying policy, DNS, load balancer, or certificate
  changes.

[Back to top](#safety)
