# Workspace Operations

[Back to README](../README.md)

Grayhaven infrastructure uses OpenTofu workspaces to separate shared baseline
resources from environment-specific runtime infrastructure.

## Table of Contents

- [Supported Workspaces](#supported-workspaces)
- [Baseline Workflow](#baseline-workflow)
- [Staging Workflow](#staging-workflow)
- [Production Workflow](#production-workflow)
- [Policy Management](#policy-management)
- [Certificate Selectors](#certificate-selectors)
- [State Safety](#state-safety)

## Supported Workspaces

The supported workspaces are:

- `baseline`
- `staging`
- `prod`

The `baseline` workspace manages shared resources that staging and production
depend on, including the DigitalOcean project, DNS zones, mail DNS records, CAA
records, and the default VPC.

The default VPC is named `grayhaven-core-baseline-vpc` and is managed as a
dedicated baseline resource instead of using the environment VPC module. It is
a non-runtime safety VPC and must survive accidental baseline destroy attempts.
Environment droplets are explicitly assigned to non-default environment VPCs.

The `staging` and `prod` workspaces manage environment-specific VPCs, droplets,
firewalls, web DNS records, droplet DNS records, and load balancers when the
compute policy requires them.

[Back to top](#workspace-operations)

## Baseline Workflow

Select the baseline workspace before managing shared resources:

```bash
tofu workspace select baseline
tofu plan
tofu apply
```

The baseline workspace must exist before staging or production can be applied
from an empty DigitalOcean account, because environment workspaces discover the
shared project and DNS zones created by baseline.

Do not destroy the `baseline` workspace. Staging and production depend on the
shared resources it manages, and destroying baseline can cause production
outages for mail and HTTPS services.

[Back to top](#workspace-operations)

## Staging Workflow

Select the staging workspace before deploying test infrastructure:

```bash
tofu workspace select staging
tofu plan
tofu apply
```

Staging website records use the `staging.<domain>` DNS namespace. Staging reads
the `staging` branch from `grayhaven-vault`.

Staging defaults to the `main` branch of `grayhaven-config-ansible`, but it can
test a specific config branch on a fresh deployment:

```bash
tofu apply -var 'grayhaven_config_repo_ref=<branch-name>'
```

Staging can also test infrastructure policy files from an infra feature branch:

```bash
tofu apply -var 'grayhaven_infra_policy_repo_ref=<branch-name>'
```

[Back to top](#workspace-operations)

## Production Workflow

Select the production workspace before managing production infrastructure:

```bash
tofu workspace select prod
tofu plan
tofu apply
```

Production website records use the apex, `www`, and `dev` hostnames for each
managed domain. Production reads `main` from both the public config repository
and the private vault repository.

[Back to top](#workspace-operations)

## Policy Management

Committed policy files define environment behavior:

- `policy/compute.yml`
- `policy/firewall/staging.yml`
- `policy/firewall/prod.yml`

The compute policy declares bastion instances, web instances, the active
control bastion, and web TLS mode. Changing the active control bastion changes
the `bastion.*` DNS record and the tags used by Ansible to identify the runner
host. Manual failover is required when the active control bastion is changed.

When web hosts scale from one node to two or more nodes in `auto` TLS mode,
OpenTofu creates a DigitalOcean load balancer and points web DNS at it. A
manual Ansible run from the active control bastion is recommended immediately
after web scaling operations so backend nginx configuration converges quickly.

Adding or removing nodes from an existing load-balanced layout does not require
host certificate issuance. Moving between host TLS and load-balancer TLS can
produce a short transition window while DNS, load balancer certificates, and
Ansible backend configuration converge.

[Back to top](#workspace-operations)

## Certificate Selectors

`grayhaven-vault/config.yml` contains the `certificate_environment` selector.
OpenTofu reads that selector from the local vault checkout.

In host TLS mode:

- `staging` uses Let's Encrypt staging through Certbot DNS-01.
- `production` uses live Let's Encrypt through Certbot DNS-01.

In load balancer TLS mode:

- `staging` uses a self-signed custom certificate on the DigitalOcean load
  balancer.
- `production` uses a DigitalOcean-managed live Let's Encrypt certificate on
  the load balancer.

The `grayhaven_certificate_environment` OpenTofu variable can force a
certificate environment during a fresh test deployment:

```bash
tofu apply -var 'grayhaven_certificate_environment=staging'
```

Deployment overrides are for fresh test deployments only. Changing overrides on
existing environments is undefined operational behavior and is not recommended.

[Back to top](#workspace-operations)

## State Safety

Baseline resources are configured with OpenTofu destroy protection so accidental
baseline destroy attempts fail before removing shared resources.

State is encrypted locally through the configured OpenTofu state encryption
passphrase. Keep state backups private and do not commit them.

[Back to top](#workspace-operations)
