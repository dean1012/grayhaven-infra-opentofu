# Workspace Operations

[Back to README](../README.md)

Grayhaven infrastructure uses OpenTofu workspaces to separate shared baseline
resources from environment-specific runtime infrastructure.

## Table of Contents

- [Supported Workspaces](#supported-workspaces)
- [Baseline Workflow](#baseline-workflow)
- [Staging Workflow](#staging-workflow)
- [Production Workflow](#production-workflow)
- [State Safety](#state-safety)

## Supported Workspaces

The supported workspaces are:

- `baseline`
- `staging`
- `prod`

The `baseline` workspace manages shared resources that staging and production
depend on, including the DigitalOcean project, DNS zones, mail DNS records, CAA
records, and the default VPC.

The `staging` and `prod` workspaces manage environment-specific VPCs, droplets,
firewalls, web DNS records, and droplet DNS records.

[Back to top](#workspace-operations)

## Baseline Workflow

Select the baseline workspace before managing shared resources:

```bash
tofu workspace select baseline
tofu plan
tofu apply
```

The baseline workspace must exist before staging or production can be applied
from an empty DigitalOcean account, because the environment workspaces discover
the shared project and DNS zones created by baseline.

[Back to top](#workspace-operations)

## Staging Workflow

Select the staging workspace before deploying test infrastructure:

```bash
tofu workspace select staging
tofu plan
tofu apply
```

Staging website records use the `staging.<domain>` DNS namespace. Ansible uses
the `env-staging` droplet tag to scope dynamic inventory and uses Let's Encrypt
staging certificates for web hosts.

[Back to top](#workspace-operations)

## Production Workflow

Select the production workspace before reviewing production infrastructure:

```bash
tofu workspace select prod
tofu plan
```

Production website records use the apex, `www`, and `dev` hostnames for each
managed domain. Ansible uses the `env-prod` droplet tag to scope dynamic
inventory and uses trusted Let's Encrypt certificates for web hosts.

[Back to top](#workspace-operations)

## State Safety

Do not destroy the `baseline` workspace. Staging and production depend on the
shared resources it manages, and destroying baseline can cause production
outages for mail and HTTPS services.

State is encrypted locally through the configured OpenTofu state encryption
passphrase. Keep state backups private and do not commit them.

[Back to top](#workspace-operations)
