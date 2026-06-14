# Runtime Architecture

This document summarizes the supported runtime architecture for
Grayhaven Systems LLC infrastructure. Policy file schemas are documented in
[Policy Files](policy.md).

## Table of Contents

- [Supported Runtime Roles](#supported-runtime-roles)
- [Control Bastion](#control-bastion)
- [Admin SSH Keys](#admin-ssh-keys)
- [Web TLS Modes](#web-tls-modes)
- [Firewall Policy](#firewall-policy)
- [Configuration Handoff](#configuration-handoff)

## Supported Runtime Roles

Environment workspaces currently support two runtime server roles:

- `bastion`: SSH entry point and, for the selected control bastion, Ansible
  convergence runner.
- `web`: nginx-based web host managed by
  [`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible).

Stable instance keys such as `bastion-01` and `web-01` are used as OpenTofu
resource keys. Numeric `index` values in compute policy are used for generated
resource names.

[Back to top](#runtime-architecture)

## Control Bastion

The active control bastion is selected by `bastions.control_node` in the
environment compute policy. The selected bastion receives the easy
`bastion.*` DNS record and the `control-node` tag.

[`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
uses the control-node tag to identify the host that should run scheduled
Ansible convergence.

[Back to top](#runtime-architecture)

## Admin SSH Keys

The DigitalOcean SSH key name is derived from the public key comment when one is
present. When no comment is present, the name is generated from the public key
material.

[Back to top](#runtime-architecture)

## Web TLS Modes

Web TLS behavior is selected by `web.tls_mode` in environment compute policy:

- `auto`: one web host uses host TLS; two or more web hosts use load balancer
  TLS.
- `load_balancer`: always use load balancer TLS.

When web hosts scale from one node to two or more nodes in `auto` TLS mode,
OpenTofu creates a DigitalOcean load balancer and points web DNS at it. Moving
from load balancer TLS back to host TLS removes the load balancer and returns
DNS to the primary web host.

Adding or removing nodes from an existing load-balanced layout does not require
host certificate issuance. Moving between host TLS and load balancer TLS can
produce a short transition window while DNS, load balancer certificates, and
Ansible backend configuration converge.

[Back to top](#runtime-architecture)

## Firewall Policy

Cloud firewalls and host firewalld policy are both derived from the
environment-specific `firewall.yml` file in `grayhaven-vault`.

OpenTofu reads this file from the local vault checkout during plan and apply.
[`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
reads the same file from the vault checkout on the active control bastion
during convergence.

[Back to top](#runtime-architecture)

## Configuration Handoff

OpenTofu renders cloud-init data for each new droplet. During first boot, each
host is bootstrapped into
[`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
and receives the environment-specific values needed for convergence.

The cloud-init handoff writes bootstrap variables to
`/etc/grayhaven/bootstrap/bootstrap-vars.yml` and then runs `ansible-pull`
against `grayhaven-config-ansible`. All hosts receive their hostname, role,
environment, config repository ref, active control bastion selector,
certificate selector, TLS mode, and first-boot deployment public key.

Bastion hosts also receive the private vault repository URL and ref, Ansible
Vault passphrase, deployment SSH keypair, and control-node flag. Those values
are used only to prepare the first runner execution. The bootstrap playbook
removes the handoff file before starting the initial full convergence run.

Environment workspaces read `config.yml` and `firewall.yml` from the intended
`grayhaven-vault` Git ref instead of whichever branch is checked out locally.
Production uses the `main` ref and staging uses the `staging` ref.

[Back to top](#runtime-architecture)
