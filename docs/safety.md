# Safety

This document describes Grayhaven Systems LLC operational safety guidelines.

## Table of Contents

- [OpenTofu Workspace Environment](#opentofu-workspace-environment)
- [Sensitive Output](#sensitive-output)
- [State Safety](#state-safety)

## OpenTofu Workspace Environment

The `baseline` and `prod` workspace environments should not be destroyed.
Destroying these environments will result in production outages.

[Back to top](#safety)

## Sensitive Output

Keep terminal output private until reviewed. OpenTofu normally redacts values
marked sensitive, but plan and apply output can still contain operational
details and may expose secrets if future changes fail to mark sensitive values
correctly.

Recommended handling:

- Keep OpenTofu environment variables out of shell history.
- Store `grayhaven.env` outside of this repository.
- Avoid sharing raw `tofu plan` or `tofu apply` output without reviewing it
  first.
- Keep private keys, Ansible Vault passphrases, DigitalOcean API tokens, state
  encryption passphrases, and other secrets out of GitHub issues, comments,
  pull requests, and commit history.

[Back to top](#safety)

## State Safety

State is encrypted locally through workspace-specific OpenTofu state
encryption passphrases. Keep state backups private and do not commit them.

Local `tofu test` validation should run from a temporary state-free copy of
this repository. For instructions on doing this safely, please see
[CONTRIBUTING.md](../CONTRIBUTING.md#local-validation).

Recommended state handling:

- Keep state encryption passphrases out of shell history and committed files.
- Keep `terraform.tfstate*`, `terraform.tfstate.d/`, `.state-backups/`, and
  plan files private.
- Keep local state backed up regularly with a copy stored offsite at all times.
- Back up local state before large refactors or provider upgrades.
- Review plans carefully before applying.

[Back to top](#safety)
