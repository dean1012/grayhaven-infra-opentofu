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

`policy/default-vault-config.yml` is a baseline fallback for values normally
read from the private vault repository. It is not an environment policy set.

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

Changing the active control bastion changes the `bastion.*` DNS record and the
tags used by
[`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
to identify the runner host.

[Back to top](#policy-files)

## DNS Policy

DNS policy is split by workspace ownership:

- `policy/baseline/dns.yml` defines managed DNS zones and baseline-owned
  records.
- `policy/staging/dns.yml` and `policy/prod/dns.yml` define the domains that
  receive computed environment DNS records.

The DNS policy separates baseline and environment ownership. DNS zones and
shared records such as MX, SPF, DKIM, DMARC, and CAA records belong under
`protected_records` in `policy/baseline/dns.yml` and are baseline resources
with OpenTofu destroy protection. Less critical baseline records can be placed
under `records`; they are managed by the baseline workspace but are not
protected from destroy.

Computed environment records are controlled under each domain's `environment`
block in `policy/staging/dns.yml` and `policy/prod/dns.yml`:

- `environment.apex: true` creates `staging.<domain>` in `staging` and
  `<domain>` in `prod`.
- `environment.web_aliases: true` creates `www.staging.<domain>` and
  `dev.staging.<domain>` in `staging`, or `www.<domain>` and `dev.<domain>`
  in `prod`.

Both fields default to false when omitted. `environment.web_aliases` requires
`environment.apex`; valid combinations are true/true, true/false, and
false/false.

DNS records are created in ordered type groups to reduce provider-side DNS
transaction contention:

- computed environment records: A, then CNAME;
- baseline `protected_records`: A, CNAME, MX, TXT, then CAA;
- baseline `records`: A, CNAME, then TXT.

The implementation filters the small DNS policy map once per supported record
type. Because the supported type set is fixed, this remains O(n) with a small
constant factor and is an intentional readability tradeoff.

For hosted web domains, keep
[`grayhaven-vault-example`](https://github.com/dean1012/grayhaven-vault-example)
`hosted_domains` data and the relevant DNS policy files aligned. Each hosted
domain should exist in `policy/baseline/dns.yml` and in each environment policy
where the domain should receive runtime records. Hosted web domains should set
both `environment.apex: true` and `environment.web_aliases: true` in the target
environment policy, and each domain with both fields set to true should have
matching `hosted_domains` data so
[`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
can converge the corresponding vhosts.

To add a hosted domain:

1. Add the domain to `policy/baseline/dns.yml`.
2. Add required baseline shared records under `protected_records`.
3. Add optional baseline records that do not need destroy protection under
   `records`.
4. Add the domain to `policy/staging/dns.yml`, `policy/prod/dns.yml`, or both.
5. Set `environment.apex: true` in each environment that should receive an
   apex A record.
6. Set `environment.web_aliases: true` when the environment should receive
   `www` and `dev` aliases.
7. Run `tofu plan` in `baseline` and review the shared DNS additions.
8. Run `tofu plan` in `staging` or `prod` and review only environment DNS
   additions.
9. Update the `hosted_domains` contract documented in
   [`grayhaven-vault-example`](https://github.com/dean1012/grayhaven-vault-example)
   so
   [`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
   can converge the matching vhosts.

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

The `grayhaven_config_repo_ref`, `grayhaven_infra_policy_repo_ref`, and
`grayhaven_certificate_environment` variables are testing-related
fresh-deployment controls. Changing them on an existing environment will result
in undefined operational behavior and is not recommended.

[Back to top](#policy-files)
