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

Policy files are committed under `policy/`:

- `policy/compute.yml`
- `policy/dns.yml`
- `policy/ssh-keys.yml`
- `policy/firewall/staging.yml`
- `policy/firewall/prod.yml`

Names and DigitalOcean tags follow the conventions documented in
[Infrastructure Naming & Tagging Conventions](naming-tagging-conventions.md).

[Back to top](#policy-files)

## Compute Policy

`policy/compute.yml` declares bastion instances, web instances, the active
control bastion, and web TLS mode.

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

`policy/dns.yml` defines managed DNS zones, baseline-owned records, and which
domains receive computed environment DNS records.

The DNS policy separates baseline and environment ownership. DNS zones and
shared records such as MX, SPF, DKIM, DMARC, and CAA records belong under
`protected_records` and are baseline resources with OpenTofu destroy
protection. Less critical baseline records can be placed under `records`; they
are managed by the baseline workspace but are not protected from destroy.

Computed environment records are controlled under each domain's `environment`
block:

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
`hosted_domains` data and `policy/dns.yml` aligned. Each hosted domain should
set both `environment.apex: true` and `environment.web_aliases: true`, and
each domain with both fields set to true should have matching
`hosted_domains` data so
[`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
can converge the corresponding vhosts.

To add a hosted domain:

1. Add the domain to `policy/dns.yml`.
2. Add required baseline shared records under `protected_records`.
3. Add optional baseline records that do not need destroy protection under
   `records`.
4. Set `environment.apex: true`.
5. Set `environment.web_aliases: true` when the domain should receive `www`
   and `dev` aliases.
6. Run `tofu plan` in `baseline` and review the shared DNS additions.
7. Run `tofu plan` in `staging` or `prod` and review only environment DNS
   additions.
8. Update the `hosted_domains` contract documented in
   [`grayhaven-vault-example`](https://github.com/dean1012/grayhaven-vault-example)
   so
   [`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
   can converge the matching vhosts.

[Back to top](#policy-files)

## Admin SSH Key Policy

`policy/ssh-keys.yml` defines admin SSH public keys under `admin_ssh_keys`.
Each entry uses a stable internal key and includes:

- `title`: the human-readable label and DigitalOcean SSH key name.
- `public_key`: the public SSH key material.

The baseline workspace creates and manages the DigitalOcean SSH key resources.
Staging and production look up those baseline-managed keys by `title` and
attach every configured admin key to every bastion and web droplet.

To add or rotate an admin key:

1. Update `policy/ssh-keys.yml`.
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

The firewall policy files drive DigitalOcean hardware firewalls in this
repository and local firewalld policy in
[`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible):

- `policy/firewall/staging.yml`
- `policy/firewall/prod.yml`

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
