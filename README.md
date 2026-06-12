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
- [Deployment Quick Reference](#deployment-quick-reference)
- [Other Documentation](#other-documentation)
- [Contributing](#contributing)
- [License](#license)

## Scope

- Manage shared baseline resources and separate staging/production runtime
  environments.
- Provision DigitalOcean VPCs, droplets, hardware firewalls, load balancers,
  DNS records, SSH keys, and project assignments.
- Define compute, DNS, firewall, and SSH key behavior through committed policy
  files.
- Bootstrap hosts into
  [`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
  for ongoing convergence.
- Read operational selectors from a local checkout of the private
  `grayhaven-vault` repository.
- Keep OpenTofu state encrypted locally.

This repository is not a general-purpose deployment template. Deploying similar
automation for another organization requires review and adaptation.

[Back to top](#grayhaven-infrastructure-opentofu)

## Requirements

This repository must be initialized and configured before use. This process is
documented in [Setup](docs/setup.md).

[Back to top](#grayhaven-infrastructure-opentofu)

## Deployment Quick Reference

Select the target workspace, review a plan, and apply only after the proposed
changes are understood.

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

For staging and production, the approved `tofu apply` is the single command
that carries the environment from infrastructure provisioning through
configuration convergence. It provisions DigitalOcean resources, renders
cloud-init, bootstraps hosts into
[`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible),
and starts full Ansible convergence from the active control bastion.

See [Operations](docs/operations.md) for plan/apply safety, destroy procedures,
control-node changes, TLS-mode changes, secret rotation, and state safety.

[Back to top](#grayhaven-infrastructure-opentofu)

## Other Documentation

- [Setup](docs/setup.md)
- [Workspaces](docs/workspaces.md)
- [Policy Files](docs/policy.md)
- [Operations](docs/operations.md)
- [Infrastructure Conventions](docs/conventions.md)
- [Troubleshooting](docs/troubleshooting.md)

[Back to top](#grayhaven-infrastructure-opentofu)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for validation commands and contribution
guidelines.

[Back to top](#grayhaven-infrastructure-opentofu)

## License

MIT

[Back to top](#grayhaven-infrastructure-opentofu)
