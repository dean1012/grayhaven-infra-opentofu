# Infrastructure Naming & Tagging Conventions

Grayhaven infrastructure uses consistent names and DigitalOcean tags so resources
are easy to audit, filter, and operate during routine changes.

## Table of Contents

- [Naming](#naming)
- [DigitalOcean Tags](#digitalocean-tags)
- [Operational Use](#operational-use)

## Naming

Resource names use stable, descriptive segments:

```text
grayhaven-<project>-<environment>-<role-or-service>
```

Indexed host resources add a two-digit instance number:

```text
grayhaven-<project>-<environment>-<role>-NN
```

Current project segments are:

- `core`: primary runtime infrastructure such as web hosts, VPCs, and load
  balancers.
- `sec`: security and access infrastructure such as bastion hosts.

Examples:

- `grayhaven-core-baseline-vpc`
- `grayhaven-core-prod-vpc`
- `grayhaven-core-prod-web-01`
- `grayhaven-sec-prod-bastion-01`
- `grayhaven-core-prod-web-fw`
- `grayhaven-core-prod-web-lb`

DNS hostnames follow the same role and index pattern. Production hostnames live
under `grayhavensystems.com`; staging hostnames live under
`staging.grayhavensystems.com`.

[Back to top](#infrastructure-naming--tagging-conventions)

## DigitalOcean Tags

DigitalOcean tags are part of the operational contract for taggable resources.
They identify ownership, environment, role, firewall scope, TLS mode, and
Ansible convergence state.

All taggable resources contain one or more of the following common tags as
appropriate:

- `client-<client>`
- `env-<environment>`
- `managed-by-opentofu`
- `configured-by-ansible`
- `tls-mode-host` or `tls-mode-load-balancer`

Resources may contain these additional tags as appropriate:

- `project-<project>`
- `role-<role>`
- `scope-<scope>`
- `control-node`
- `control-capable`

For example, web droplets use a scope tag such as
`scope-grayhaven-core-prod-web` so firewall rules can target the current web
pool without listing individual droplet IDs.

[Back to top](#infrastructure-naming--tagging-conventions)

## Operational Use

Tags support several operational paths:

- Hardware firewalls target the `scope-*` tags instead of individual droplet
  IDs.
- [`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
  inventory groups hosts by DigitalOcean tags.
- The `control-node` tag identifies the bastion expected to run scheduled
  Ansible convergence.
- Environment tags make staging and production resources easy to distinguish in
  the DigitalOcean console.
- [`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
  reads the OpenTofu-managed TLS mode tag while converging web hosts, so TLS
  architecture changes should be made through OpenTofu rather than by editing
  tags directly in the DigitalOcean console.

When adding new resource types, keep names and tags aligned with these patterns
unless there is a clear operational reason to do otherwise.

[Back to top](#infrastructure-naming--tagging-conventions)
