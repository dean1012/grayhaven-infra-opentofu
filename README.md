# Grayhaven Infrastructure (OpenTofu)

Infrastructure-as-code repository for Grayhaven Systems LLC using OpenTofu and
DigitalOcean.

## Overview

This repository contains reusable OpenTofu modules and deployment configuration
used to provision and manage Grayhaven Systems LLC infrastructure.

Current infrastructure goals include:

- Reusable OpenTofu module architecture
- Secure DigitalOcean infrastructure provisioning
- Bastion-based administrative access model
- Tag-driven firewall management
- Encrypted local OpenTofu state
- Workspace-separated baseline, staging, and production infrastructure
- GitHub Actions validation workflows
- Enterprise-oriented naming and tagging standards

## Repository Scope

This repository is intended for:

- Grayhaven Systems LLC infrastructure
- Personal infrastructure projects
- Public portfolio and educational reference

Client infrastructure, credentials, deployment data, and operational state are
not stored in this repository.

## Planned Infrastructure

Initial planned infrastructure includes:

- Shared baseline resources plus separate staging and production runtime
  infrastructure
- Bastion host
- DigitalOcean VPC networking
- Tag-driven firewall management
- FQDN-based droplet naming with forward-confirmed reverse DNS (FCrDNS)
- Reusable infrastructure modules
- CI validation workflows

## Requirements

- OpenTofu
- DigitalOcean account
- DigitalOcean API token
- SSH public keys uploaded to DigitalOcean

## Deployment Quick Reference

Apply the shared baseline before deploying an environment:

```bash
tofu workspace select baseline
tofu apply
```

Deploy staging:

```bash
tofu workspace select staging
tofu apply
```

Deploy production with live Let's Encrypt certificates:

```bash
tofu workspace select prod
tofu apply
```

Deploy production while forcing Let's Encrypt staging certificates:

```bash
tofu workspace select prod
tofu apply -var 'grayhaven_certbot_environment=staging'
```

Staging can test a specific `grayhaven-config-ansible` branch with
`grayhaven_config_repo_ref`. Production always uses `main`.

## Repository Structure

```text
docs/        Project and operational documentation
modules/     Reusable OpenTofu modules
templates/   OpenTofu-rendered templates for generated config files
```

## Documentation

- [Workspace Operations](docs/workspaces.md)

## Status

Project initialization in progress.
