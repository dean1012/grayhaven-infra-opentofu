# Infrastructure Conventions

[Return to README](../README.md)

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

[Back to top](#infrastructure-conventions)

## DigitalOcean Tags

DigitalOcean tags are part of the operational contract. They identify ownership,
environment, role, firewall scope, TLS mode, and Ansible convergence state.

Common tags on environment droplets include:

- `client-grayhaven`
- `env-staging` or `env-prod`
- `managed-by-opentofu`
- `configured-by-ansible`
- `tls-mode-host` or `tls-mode-load-balancer`

Role and scope tags include:

- `project-core`
- `project-sec`
- `role-web`
- `role-bastion`
- `scope-grayhaven-core-<environment>-web`
- `scope-grayhaven-sec-<environment>-bastion`

Bastion instance tags also include:

- `bastion-NN`
- `control-node` on the active control bastion
- `control-capable` on non-active bastions

Web instance tags also include:

- `web-NN`

[Back to top](#infrastructure-conventions)

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
- TLS mode tags make the active web TLS architecture visible on droplets.

When adding new resource types, keep names and tags aligned with these patterns
unless there is a clear operational reason to do otherwise.

[Back to top](#infrastructure-conventions)
