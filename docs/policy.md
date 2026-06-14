# Policy Files

Committed policy files define the intended infrastructure shape for each
workspace environment. This document describes the supported policy file
schemas.

## Table of Contents

- [Overview](#overview)
- [DNS Policy](#dns-policy)
  - [DNS Policy Schema](#dns-policy-schema)
  - [Baseline DNS Policy](#baseline-dns-policy)
  - [Environment DNS Policy](#environment-dns-policy)
- [Firewall Policy](#firewall-policy)
- [Admin SSH Key Policy](#admin-ssh-key-policy)
- [Compute Policy](#compute-policy)

## Overview

Each workspace environment contains a set of policy configuration files stored
in `policy/<workspace>`.

The `baseline` workspace environment supports DNS and admin SSH key policy
configuration. All other workspace environments support compute and DNS policy
configuration.

[Back to top](#policy-files)

## DNS Policy

DNS zones and records are handled by DNS policy files and through computed,
automatic DNS records set up by OpenTofu and DigitalOcean. For more information
on automatic records, please see the [DNS architecture documentation](dns-architecture.md).

### DNS Policy Schema

Supported top-level keys:

- `ttl`: default TTL for managed DNS records.
- `domains`: map of managed domain entries.

Supported domain keys:

- `domains.<domain_key>.name`: public domain name.
- `domains.<domain_key>.protected_records`: Optional. DNS records with OpenTofu
  destroy protection.
- `domains.<domain_key>.records`: Optional. DNS records without OpenTofu destroy
  protection.

`protected_records` supports these DNS record types:

- `A`
- `CNAME`
- `TXT`

`records` supports these DNS record types:

- `A`
- `CNAME`
- `TXT`

Each record entry supports:

- `type`: DNS record type.
- `name`: record name.
- `value`: record target or value.
- `ttl`: optional per-record TTL override.

### Baseline DNS Policy

`policy/baseline/dns.yml` is intended to set up the DNS zone for each supported
domain and any records that would be shared across workspace environments, such
as mail-related records.

Baseline DNS policy supports the following additional `protected_records` types:

- `MX`
- `CAA`

MX records support a `priority` attribute for MX-specific record compatibility.

CAA records support `flags` and `tag` attributes for CAA-specific record
compatibility.

All supported domains should be defined in this file.

Example shape:

```yaml
ttl: 300

domains:
  example:
    name: example.com
    protected_records:
      mail_a:
        type: A
        name: mail
        value: 192.0.2.10
      mx_primary:
        type: MX
        name: "@"
        value: mail.example.com.
        priority: 10
      spf_txt:
        type: TXT
        name: "@"
        value: "v=spf1 include:mail.example.com ~all"
      caa_letsencrypt:
        type: CAA
        name: "@"
        flags: 0
        tag: issue
        value: letsencrypt.org.
    records:
      status_txt:
        type: TXT
        name: status
        value: "status=ok"
```

### Environment DNS Policy

Environment-specific records are created in `policy/<workspace>/dns.yml` and use
the same format with the addition of an `environment` domain key:

- `domains.<domain_key>.environment.apex`: automatically creates an A record for
  the environment apex. Optional. Defaults to false.
- `domains.<domain_key>.environment.web_aliases`: automatically creates `www`
  and `dev` CNAME aliases to the environment apex. Optional. Defaults to false.

Setting `environment.web_aliases` to true requires that `environment.apex` also
be true. Valid combinations are true/true, true/false, and false/false.

If you have any `hosted_domains` configured in
`grayhaven-vault`, it is
strongly recommended that you set `environment.web_aliases` and
`environment.apex` to true.

Example shape:

```yaml
ttl: 300

domains:
  example:
    name: example.com
    environment:
      apex: true
      web_aliases: true
```

[Back to top](#policy-files)

## Firewall Policy

Firewall policy is managed through `firewall.yml` in the private
`grayhaven-vault` repository.
This keeps DigitalOcean cloud firewall policy and host firewalld policy tied to
the same environment-specific configuration.

OpenTofu reads `firewall.yml` from the local vault checkout during plan and
apply. [`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
reads the same file from the vault checkout on the active control bastion during
convergence.

When load-balancer TLS is active, OpenTofu derives the effective web cloud
firewall from `firewall.yml` by allowing web origin HTTP from the DigitalOcean
load balancer and omitting direct web origin HTTPS.

The public
[grayhaven-vault-example](https://github.com/dean1012/grayhaven-vault-example)
repository documents the expected
[firewall.yml schema](https://github.com/dean1012/grayhaven-vault-example/blob/main/docs/schema.md#firewallyml).

[Back to top](#policy-files)

## Admin SSH Key Policy

The `policy/baseline/ssh-keys.yml` policy configuration file defines public SSH
keys that are provided to DigitalOcean for first-boot SSH access to new servers.
The bootstrap account is removed by
[`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
during convergence.

These keys are only useful for first-boot access and configuration. If you are
looking to manage user SSH access to a server, please refer to the
[managing users documentation](https://github.com/dean1012/grayhaven-vault-example/blob/main/docs/operations.md#managing-users)
in the
[`grayhaven-vault-example`](https://github.com/dean1012/grayhaven-vault-example)
repository and modify
`grayhaven-vault` appropriately.

Supported top-level keys:

- `admin_ssh_keys`: list of managed admin SSH public keys.

Example shape:

```yaml
admin_ssh_keys:
  - >-
    ssh-ed25519
    AAAAexamplePublicKeyMaterial
    admin@example.com
```

[Back to top](#policy-files)

## Compute Policy

`policy/staging/compute.yml` and `policy/prod/compute.yml` declare bastion
instances, web instances, the active control bastion, and web TLS mode.

Supported top-level keys:

- `bastions`: bastion role policy.
- `web`: web role policy.

Supported bastion keys:

- `bastions.control_node`: bastion instance key selected as the active control
  bastion.
- `bastions.instances`: map of bastion instances.
- `bastions.instances.<instance_key>.index`: numeric index used for generated
  resource names.
- `bastions.instances.<instance_key>.size`: optional DigitalOcean droplet size.
- `bastions.instances.<instance_key>.image`: optional DigitalOcean image slug.

Supported web keys:

- `web.tls_mode`: `auto` or `load_balancer`.
- `web.instances`: map of web instances.
- `web.instances.<instance_key>.index`: numeric index used for generated
  resource names.
- `web.instances.<instance_key>.size`: optional DigitalOcean droplet size.
- `web.instances.<instance_key>.image`: optional DigitalOcean image slug.

`bastions.control_node` must match a key under `bastions.instances`. Each
environment compute policy must define at least one bastion and one web host.
`web.tls_mode` defaults to `auto` when omitted.

Supported TLS modes:

- `auto`: uses host TLS when the environment has one web host and load-balancer
  TLS when the environment has two or more web hosts.
- `load_balancer`: always uses DigitalOcean load-balancer TLS.

Host TLS points web DNS at the primary web host. Load-balancer TLS creates a
DigitalOcean load balancer, points web DNS at the load balancer, and configures
web hosts as HTTP backends for load-balanced traffic.

Example shape:

```yaml
bastions:
  control_node: bastion-01
  instances:
    bastion-01:
      index: 1

web:
  tls_mode: auto
  instances:
    web-01:
      index: 1
```

[Back to top](#policy-files)
