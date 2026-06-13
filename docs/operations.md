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
- [Bastion Failover](#bastion-failover)
- [Updating Workspace Environment TLS Mode](#updating-workspace-environment-tls-mode)
- [Certificate Selectors](#certificate-selectors)

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
     exit 1
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

## Certificate Selectors

`grayhaven-vault/config.yml` contains the `certificate_environment` selector.
OpenTofu reads that selector from the workspace-selected Git ref in the local
vault checkout:

- `staging`: `staging:config.yml`
- `prod`: `main:config.yml`

The checked-out vault branch does not affect selector loading. Fetch the
expected refs before planning or applying:

```bash
git -C "$TF_VAR_grayhaven_vault_checkout_path" fetch origin main staging
```

In host TLS mode:

- `staging` uses Let's Encrypt staging through Certbot DNS-01.
- `production` uses live Let's Encrypt through Certbot DNS-01.

In load balancer TLS mode:

- `staging` uses a self-signed custom certificate on the DigitalOcean load
  balancer.
- `production` uses a DigitalOcean-managed live Let's Encrypt certificate on
  the load balancer.

[Back to top](#operations)
