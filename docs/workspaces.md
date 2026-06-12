# Workspaces

Grayhaven infrastructure uses OpenTofu workspaces to separate shared baseline
resources from environment-specific runtime infrastructure.

## Table of Contents

- [Supported Workspaces](#supported-workspaces)
- [Baseline](#baseline)
- [Staging](#staging)
- [Production](#production)
- [Workspace Boundaries](#workspace-boundaries)

## Supported Workspaces

The supported workspaces are:

- `baseline`
- `staging`
- `prod`

Do not create additional operational workspaces without first updating policy,
tests, documentation, and backup procedures.

[Back to top](#workspaces)

## Baseline

The `baseline` workspace manages shared resources that staging and production
depend on, including:

- the DigitalOcean project;
- admin SSH keys;
- DNS zones;
- mail DNS records;
- CAA records;
- the default baseline VPC.

The default VPC is named `grayhaven-core-baseline-vpc` and is managed as a
dedicated baseline resource instead of using the environment VPC module. It is
a non-runtime safety VPC and must survive accidental baseline destroy attempts.
Environment droplets are explicitly assigned to non-default environment VPCs.

Do not destroy the `baseline` workspace. Staging and production depend on the
shared resources it manages, and destroying baseline can cause production
outages for mail and HTTPS services.

[Back to top](#workspaces)

## Staging

The `staging` workspace manages temporary environment infrastructure used to
validate changes before promotion to production.

Staging owns environment-specific resources such as:

- the staging VPC;
- staging bastion and web droplets;
- staging firewall attachments;
- staging web DNS records;
- staging droplet DNS records;
- staging load balancers when the compute policy requires them.

Staging reads `config.yml` from the `staging` Git ref in the local
`grayhaven-vault` checkout. The vault checkout does not need to have `staging`
checked out, but the ref must be present locally.

Staging is expected to be destroyed after validation unless an active test
requires it to remain online.

[Back to top](#workspaces)

## Production

The `prod` workspace manages production runtime infrastructure.

Production owns environment-specific resources such as:

- the production VPC;
- production bastion and web droplets;
- production firewall attachments;
- production web DNS records;
- production droplet DNS records;
- production load balancers when the compute policy requires them.

Production reads `config.yml` from the `main` Git ref in the local
`grayhaven-vault` checkout. The vault checkout does not need to have `main`
checked out, but the ref must be present locally.

Production applies should be deliberate, reviewed carefully, and limited to
changes that are ready to become the live operating state.

[Back to top](#workspaces)

## Workspace Boundaries

The baseline workspace owns shared resources. Staging and production own only
their environment-specific runtime resources.

Routine commands, destroy procedures, TLS changes, state rotation, and other
operator tasks are documented in [Operations](operations.md). Policy file
structure and change procedures are documented in [Policy Files](policy.md).

[Back to top](#workspaces)
