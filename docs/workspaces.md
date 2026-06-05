# Workspace Operations

[Back to README](../README.md)

Grayhaven infrastructure uses OpenTofu workspaces to separate shared baseline
resources from environment-specific runtime infrastructure.

## Table of Contents

- [Supported Workspaces](#supported-workspaces)
- [Baseline Workflow](#baseline-workflow)
- [Staging Workflow](#staging-workflow)
- [Production Workflow](#production-workflow)
- [Certificate Mode Override](#certificate-mode-override)
- [State Safety](#state-safety)

## Supported Workspaces

The supported workspaces are:

- `baseline`
- `staging`
- `prod`

The `baseline` workspace manages shared resources that staging and production
depend on, including the DigitalOcean project, DNS zones, mail DNS records, CAA
records, and the default VPC.

The default VPC is managed as a dedicated baseline resource instead of using the
environment VPC module. This allows baseline destroy protection to guard the
default VPC without changing staging or production VPC lifecycle behavior.

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

Select the production workspace before managing production infrastructure:

```bash
tofu workspace select prod
tofu plan
tofu apply
```

Production website records use the apex, `www`, and `dev` hostnames for each
managed domain. Ansible uses the `env-prod` droplet tag to scope dynamic
inventory and uses trusted Let's Encrypt certificates for web hosts unless a
certificate mode override is supplied.

[Back to top](#workspace-operations)

## Certificate Mode Override

Ansible derives Certbot mode from the active environment by default. To
explicitly use Let's Encrypt staging certificates, pass the override at plan or
apply time:

```bash
tofu apply -var 'grayhaven_certbot_environment=staging'
```

Valid override values are `staging` and `production`. Omit the variable to use
the environment default.

[Back to top](#workspace-operations)

## State Safety

Do not destroy the `baseline` workspace. Staging and production depend on the
shared resources it manages, and destroying baseline can cause production
outages for mail and HTTPS services.

Baseline resources are configured with OpenTofu destroy protection so accidental
baseline destroy attempts fail before removing shared resources.

State is encrypted locally through the configured OpenTofu state encryption
passphrase. Keep state backups private and do not commit them.

[Back to top](#workspace-operations)
