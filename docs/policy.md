# Policy Files

Committed policy files define the intended infrastructure shape.

## Table of Contents

- [Overview](#overview)
- [Compute Policy](#compute-policy)
- [DNS Policy](#dns-policy)
- [Admin SSH Key Policy](#admin-ssh-key-policy)
- [Firewall Policy](#firewall-policy)
- [Policy Overrides](#policy-overrides)

## Overview

Policy files are committed under workspace-specific directories:

- `policy/baseline/`
- `policy/staging/`
- `policy/prod/`

Workspace policy directories contain files relevant to the resources owned by
that workspace:

- `policy/baseline/`: `dns.yml`, `ssh-keys.yml`
- `policy/staging/`: `compute.yml`, `dns.yml`, `firewall.yml`
- `policy/prod/`: `compute.yml`, `dns.yml`, `firewall.yml`

OpenTofu selects workspace-owned policy files from the directory that matches
the active workspace. The `baseline` workspace uses `policy/baseline/`,
`staging` uses `policy/staging/`, and `prod` uses `policy/prod/`. Baseline
admin SSH key policy is read by all workspaces because baseline owns the
DigitalOcean SSH key resources.

Baseline policy owns shared resources such as DNS zones, baseline DNS records,
and admin SSH key resources. Staging and production policy own runtime resources
such as droplets, cloud firewalls, and computed environment DNS records.

Names and DigitalOcean tags follow the conventions documented in
[Infrastructure Naming & Tagging Conventions](naming-tagging-conventions.md).

[Back to top](#policy-files)

## Compute Policy

`policy/<environment>/compute.yml` declares bastion instances, web instances,
the active control bastion, and web TLS mode for `staging` and `prod`.

Stable instance keys such as `bastion-01` and `web-01` are used as OpenTofu
resource keys. The declared bastion control node receives the easy
`bastion.*` DNS record and is the only bastion expected to run the scheduled
Ansible runner.

Web TLS behavior is selected by `web.tls_mode`:

- `auto`: one web host uses host TLS; two or more web hosts use load balancer
  TLS.
- `load_balancer`: always use load balancer TLS.

When web hosts scale from one node to two or more nodes in `auto` TLS mode,
OpenTofu creates a DigitalOcean load balancer and points web DNS at it. A
manual Ansible run from the active control bastion is recommended immediately
after web scaling operations so backend nginx configuration converges quickly.

Moving from load-balancer TLS back to host TLS removes the load balancer and
returns DNS to the primary web host. Confirm the certificate selector is still
appropriate before applying that change.

Adding or removing nodes from an existing load-balanced layout does not require
host certificate issuance. Moving between host TLS and load-balancer TLS can
produce a short transition window while DNS, load balancer certificates, and
Ansible backend configuration converge.

Changing the active control bastion changes the `bastion.*` DNS record and the
tags used by
[`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
to identify the runner host.

[Back to top](#policy-files)

## DNS Policy

DNS policy file behavior and ownership are described in [DNS](dns.md). This
section documents the policy file shape.

`policy/baseline/dns.yml` supports:

- `ttl`: default TTL for managed DNS records.
- `domains`: map of managed domain entries.
- `domains.<key>.name`: public domain name.
- `domains.<key>.protected_records`: baseline records with OpenTofu destroy
  protection.
- `domains.<key>.records`: baseline records without OpenTofu destroy
  protection.

`protected_records` supports A, CNAME, MX, TXT, and CAA record types.
`records` supports A, CNAME, and TXT record types. Use `protected_records` for
MX and CAA records.

Each record entry includes:

- `type`: DNS record type.
- `name`: record name.
- `value`: record target or value.
- `ttl`: optional per-record TTL override.
- `priority`: priority for record types that use it.
- `flags`: CAA flags.
- `tag`: CAA tag.

`policy/staging/dns.yml` and `policy/prod/dns.yml` support:

- `ttl`: default TTL for computed environment DNS records.
- `domains`: map of domains that should receive computed environment records.
- `domains.<key>.name`: public domain name.
- `domains.<key>.environment.apex`: creates the environment apex record.
- `domains.<key>.environment.web_aliases`: creates `www` and `dev` aliases for
  the environment.

Both fields default to false when omitted. `environment.web_aliases` requires
`environment.apex`; valid combinations are true/true, true/false, and
false/false.

[Back to top](#policy-files)

## Admin SSH Key Policy

`policy/baseline/ssh-keys.yml` defines admin SSH public keys under
`admin_ssh_keys`. Each entry uses a stable internal key and includes:

- `title`: the human-readable label and DigitalOcean SSH key name.
- `public_key`: the public SSH key material.

The baseline workspace creates and manages the DigitalOcean SSH key resources.
Staging and production read the baseline key policy, look up those keys by
`title`, and attach every configured admin key to every bastion and web
droplet. The environment workspaces do not define separate admin key policy
files because the key resources are baseline-owned.

To add or rotate an admin key:

1. Update `policy/baseline/ssh-keys.yml`.
2. Update the private vault repository as appropriate for managed users,
   automation users, or deploy/control keys. Use the file-shape and editing
   guidance documented in
   [`grayhaven-vault-example`](https://github.com/dean1012/grayhaven-vault-example).
3. Select `baseline`.
4. Run `tofu plan` and confirm only the intended SSH key resources change.
5. Run `tofu apply`.
6. Select `staging` or `prod`.
7. Run `tofu plan` and confirm droplets will receive the expected admin key
   fingerprints.
8. Apply the environment only when the droplet SSH key change is intended for
   that environment.

Public SSH keys are safe to commit. Private SSH keys and agent material must
never be committed or printed in terminal output.

[Back to top](#policy-files)

## Firewall Policy

The firewall policy files drive DigitalOcean cloud firewalls in this
repository and local firewalld policy in
[`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible):

- `policy/staging/firewall.yml`
- `policy/prod/firewall.yml`

When changing firewall policy, validate both cloud and host-level behavior.

[Back to top](#policy-files)

## Policy Overrides

The `grayhaven_test_compute_policy_path`,
`grayhaven_test_dns_policy_path`, and `grayhaven_test_ssh_keys_policy_path`
variables exist only for offline plan tests and disposable validation
checkouts. Leave them unset for operational deployment.

The `grayhaven_config_repo_ref` and `grayhaven_infra_policy_repo_ref` variables
are testing-related fresh-deployment controls. Changing them on an existing
environment will result in undefined operational behavior and is not
recommended.

[Back to top](#policy-files)
