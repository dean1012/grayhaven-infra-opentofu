# Grayhaven Infrastructure (OpenTofu)

Infrastructure-as-code repository for Grayhaven Systems LLC using OpenTofu and DigitalOcean.

## Overview

This repository contains reusable OpenTofu modules and deployment configuration used to provision and manage Grayhaven Systems LLC infrastructure.

Current infrastructure goals include:

- Reusable OpenTofu module architecture
- Secure DigitalOcean infrastructure provisioning
- Bastion-based administrative access model
- Tag-driven firewall management
- Encrypted local OpenTofu state
- GitHub Actions validation workflows
- Enterprise-oriented naming and tagging standards

## Repository Scope

This repository is intended for:

- Grayhaven Systems LLC infrastructure
- Personal infrastructure projects
- Public portfolio and educational reference

Client infrastructure, credentials, deployment data, and operational state are not stored in this repository.

## Planned Infrastructure

Initial planned infrastructure includes:

- Shared web infrastructure in a production environment with a future goal towards adding development and staging environments
- Bastion host
- DigitalOcean VPC networking
- Tag-driven firewall management
- Reserved public IP assignments
- Reusable infrastructure modules
- CI validation workflows

## Requirements

- OpenTofu
- DigitalOcean account
- DigitalOcean API token
- SSH public keys uploaded to DigitalOcean

## Repository Structure

```text
clients/     Local deployment configuration templates
docs/        Project and operational documentation
modules/     Reusable OpenTofu modules
```

## Status

Project initialization in progress.
