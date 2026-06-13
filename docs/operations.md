# Operations

This document describes routine OpenTofu operations for Grayhaven Systems LLC
infrastructure.

## Table of Contents

- [List Available Workspaces](#list-available-workspaces)
- [Switch Active Workspace](#switch-active-workspace)
- [Provisioning or Updating Infrastructure](#provisioning-or-updating-infrastructure)
- [Deploying Staging Workspace with Ansible Testing Branch](#deploying-staging-workspace-with-ansible-testing-branch)
- [Destroy the Staging Workspace Environment](#destroy-the-staging-workspace-environment)
- [DigitalOcean API Token Rotation](#digitalocean-api-token-rotation)
- [OpenTofu State Encryption Passphrase Rotation](#opentofu-state-encryption-passphrase-rotation)
- [Ansible Vault Passphrase Rotation](#ansible-vault-passphrase-rotation)
- [grayhaven-vault Deployment SSH Keypair Rotation](#grayhaven-vault-deployment-ssh-keypair-rotation)
- [Bastion Failover](#bastion-failover)
- [Updating Workspace Environment TLS Mode](#updating-workspace-environment-tls-mode)
- [Managing Admin SSH Keys](#managing-admin-ssh-keys)

## List Available Workspaces

To list all available workspaces, from the repository root run:

```bash
tofu workspace list
```

The [Workspaces](workspaces.md) documentation details each supported workspace.

[Back to top](#operations)

## Switch Active Workspace

To change the active workspace, from the repository root run:

```bash
tofu workspace select <workspace>
```

[Back to top](#operations)

## Provisioning or Updating Infrastructure

First, change to the desired workspace, then execute `tofu plan` from the
repository root. Review planned changes carefully, then run `tofu apply` to
update the live workspace environment.

```bash
tofu workspace select <workspace>
tofu plan
tofu apply
```

[Back to top](#operations)

## Deploying Staging Workspace with Ansible Testing Branch

To run bootstrap and convergence from a
[`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
branch other than `main`, from the repository root run:

```bash
tofu workspace select staging
tofu plan -var 'grayhaven_config_repo_ref=<branch-name>'
```

Review planned changes carefully, then run this command to update the live
`staging` workspace environment:

```bash
tofu apply -var 'grayhaven_config_repo_ref=<branch-name>'
```

The `grayhaven_config_repo_ref` override is intended to be used with a fresh
`staging` workspace deployment only. If you need to change this value, you must
first destroy the `staging` workspace environment.

[Back to top](#operations)

## Destroy the Staging Workspace Environment

The `staging` workspace environment is meant to be destroyed when not in use.
To destroy the `staging` workspace environment safely, run these commands from
the repository root:

```bash
tofu workspace select staging
tofu plan -destroy
tofu destroy
```

[Back to top](#operations)

## DigitalOcean API Token Rotation

DigitalOcean API token scopes cannot be changed after token creation. If a
token is compromised, expired, or missing a required permission, create a new
token with the
[full documented scope set](setup.md#create-a-digitalocean-api-token) and
rotate the local OpenTofu environment to use the new value.

To rotate the OpenTofu DigitalOcean API token:

1. Create a new DigitalOcean API token using the permissions documented in
   [Setup](setup.md#create-a-digitalocean-api-token), adding or removing any
   desired permissions if applicable.
2. Update `$HOME/.bashrc.d/grayhaven.env`, replacing `TF_VAR_do_token` with
   your new DigitalOcean API token.
3. Reload `grayhaven.env`:

   ```bash
   source "$HOME/.bashrc.d/grayhaven.env"
   ```

4. Confirm the variable is present without printing its value:

   ```bash
   if [ -n "${TF_VAR_do_token:-}" ]; then
     printf '\033[32mTF_VAR_do_token=defined\033[0m\n'
   else
     printf '\033[31mTF_VAR_do_token=missing\033[0m\n'
   fi
   ```

5. Deploy the `staging` workspace environment to test your new DigitalOcean
   API token.
6. Destroy the `staging` workspace environment once your new DigitalOcean API
   token has been validated.
7. Delete your old DigitalOcean API token.

If you have added or removed a permission from your DigitalOcean API token,
please update the documented
[DigitalOcean API token scope table](setup.md#create-a-digitalocean-api-token).

[Back to top](#operations)

## OpenTofu State Encryption Passphrase Rotation

To rotate the OpenTofu state encryption passphrase for a given workspace
environment:

1. Temporarily back up the target workspace environment state and keep the
   backup private.

   From the repository root, replace `<workspace>` appropriately and run:

   ```bash
   workspace="<workspace>"
   backup_dir="$HOME/backups"
   timestamp="$(date -u +%Y%m%dT%H%M%SZ)"

   mkdir -p "$backup_dir"
   chmod 0700 "$backup_dir"
   tar -czf \
     "$backup_dir/grayhaven-infra-opentofu-${workspace}-state-${timestamp}.tar.gz" \
     "terraform.tfstate.d/${workspace}"
   chmod 0600 \
     "$backup_dir/grayhaven-infra-opentofu-${workspace}-state-${timestamp}.tar.gz"
   ```

2. Update `$HOME/.bashrc.d/grayhaven.env`, renaming
   `TF_VAR_state_encryption_passphrase_<workspace>` to
   `TF_VAR_state_encryption_previous_passphrase_<workspace>`.
3. Update `$HOME/.bashrc.d/grayhaven.env`, adding
   `TF_VAR_state_encryption_passphrase_<workspace>` with the new encryption
   passphrase.
4. Reload `grayhaven.env`:

   ```bash
   source "$HOME/.bashrc.d/grayhaven.env"
   ```

5. Validate both variables are present by replacing `<workspace>`
   appropriately and running this command:

   ```bash
   workspace="<workspace>"
   current_var="TF_VAR_state_encryption_passphrase_${workspace}"
   previous_var="TF_VAR_state_encryption_previous_passphrase_${workspace}"

   for var_name in "$current_var" "$previous_var"; do
     if [ -n "${!var_name:-}" ]; then
       printf '\033[32m%s=defined\033[0m\n' "$var_name"
     else
       printf '\033[31m%s=missing\033[0m\n' "$var_name"
     fi
   done
   ```

6. Select the target workspace:

   ```bash
   tofu workspace select <workspace>
   ```

7. Run `tofu plan` to confirm that OpenTofu can read the workspace
   environment state with the previous passphrase.
8. Run `tofu apply` to rotate the state encryption passphrase.
9. Update `$HOME/.bashrc.d/grayhaven.env`, removing
   `TF_VAR_state_encryption_previous_passphrase_<workspace>`.
10. Unset `TF_VAR_state_encryption_previous_passphrase_<workspace>` in your
    local shell environment:

    ```bash
    workspace="<workspace>"
    unset "TF_VAR_state_encryption_previous_passphrase_${workspace}"
    ```

11. Run `tofu plan` again to confirm that OpenTofu can read the workspace
    environment state with the new passphrase.

If anything goes wrong with the above steps, rollback by first ensuring that
`TF_VAR_state_encryption_passphrase_<workspace>` in
`$HOME/.bashrc.d/grayhaven.env` is set to the original encryption passphrase,
then restore state by executing the following from the repository root:

```bash
workspace="<workspace>"
backup_file="$HOME/backups/grayhaven-infra-opentofu-${workspace}-state-<timestamp>.tar.gz"

source "$HOME/.bashrc.d/grayhaven.env"
tar -tzf "$backup_file"
tar -xzf "$backup_file"
tofu workspace select "$workspace"
tofu plan
```

Once the state encryption passphrase has been successfully rotated, the
temporary state backup taken in step 1 above can be safely removed.

[Back to top](#operations)

## Ansible Vault Passphrase Rotation

To rotate the Ansible Vault encryption passphrase for a given workspace
environment:

1. Update `$HOME/.bashrc.d/grayhaven.env`, updating
   `TF_VAR_grayhaven_vault_password_<workspace>` with the new encryption
   passphrase.
2. Rotate the configuration Ansible Vault passphrase for the correct workspace
   environment by following the instructions located in
   [`grayhaven-vault-example`](https://github.com/dean1012/grayhaven-vault-example/blob/main/docs/operations.md#vault-password-rotation).
3. Rotate the Ansible Vault passphrase for existing resources by following the
   instructions located in
   [`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible/blob/main/docs/operations.md#vault-password-rotation).

Do not discard your original Ansible Vault passphrase until you have
successfully completed the passphrase rotation procedure.

[Back to top](#operations)

## grayhaven-vault Deployment SSH Keypair Rotation

The deploy/control key is supplied to fresh droplets through
`TF_VAR_grayhaven_ansible_deploy_public_key` and
`TF_VAR_grayhaven_ansible_deploy_private_key`. For deployed bastions, rotate
the persisted key with
[`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
`playbooks/rotate-vault-deploy-key.yml`, then update the OpenTofu variables so
future droplets receive the new key during bootstrap.

[Back to top](#operations)

## Bastion Failover

The active control bastion is selected with `bastions.control_node` in the
target environment's `policy/<environment>/compute.yml`. Only that bastion
receives the `control-node` tag and runs the scheduled Ansible runner and
poller.

To switch the active control bastion:

1. Ensure the target bastion exists in `policy/<environment>/compute.yml`.
2. Change `bastions.control_node` to the target bastion key.
3. Select the target workspace and run `tofu plan`.
4. Confirm the plan only changes the expected DNS/tag relationships.
5. Run `tofu apply`.
6. SSH to the new `bastion.*` target and start a manual config run:

```bash
sudo systemctl start grayhaven-ansible-runner.service
```

After convergence, verify the runner and poller timers are enabled only on the
new control bastion by running the following commands on each remaining
bastion:

```bash
systemctl is-enabled grayhaven-ansible-runner.timer
systemctl is-active grayhaven-ansible-runner.timer
systemctl is-enabled grayhaven-ansible-poller.timer
systemctl is-active grayhaven-ansible-poller.timer
```

Remaining bastions still operate as SSH jump points.

Automatic bastion failover is not supported at this time. You must manually
switch the active control bastion.

[Back to top](#operations)

## Updating Workspace Environment TLS Mode

To change the currently active TLS mode for a given workspace environment,
first modify `web.tls_mode` in `policy/<environment>/compute.yml`, then run the
following commands from the repository root:

```bash
tofu workspace select <workspace>
tofu plan
```

Review planned changes carefully, then run this command to update the live
workspace environment:

```bash
tofu apply
```

Policy documentation details [supported TLS modes](policy.md#compute-policy).

[Back to top](#operations)

## Managing Admin SSH Keys

Admin SSH public keys are managed in `policy/baseline/ssh-keys.yml`. Update
that baseline policy first, then update the private vault repository as
appropriate for users or automation keys by following
[`grayhaven-vault-example`](https://github.com/dean1012/grayhaven-vault-example).

[Back to top](#operations)
