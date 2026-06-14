# DNS

This document summarizes how this repository manages DNS behavior. DNS policy
file formats are documented in [Policy Files](policy.md).

Environment droplets receive FQDNs automatically. Production droplet hostnames
are suffixed by `grayhavensystems.com`; staging droplet hostnames are suffixed
by `staging.grayhavensystems.com`.

DigitalOcean creates PTR records for droplets from their configured hostnames.

The `baseline` workspace owns shared DNS zones and baseline records. Shared
records such as mail records and CAA records should be managed as protected
baseline records. Less critical baseline records can be managed as unprotected
baseline records.

Environment workspaces create computed runtime records for domains listed in
their DNS policy. `environment.apex: true` creates the environment apex record.
`environment.web_aliases: true` creates `www` and `dev` aliases for that
environment.

DNS records are created in ordered type groups to reduce provider-side DNS
transaction contention:

- computed environment records: A, then CNAME;
- baseline DNS policy `protected_records`: A, CNAME, MX, TXT, then CAA;
- environment DNS policy `protected_records`: A, CNAME, then TXT;
- DNS policy `records`: A, CNAME, then TXT.

Hosted web domains should stay aligned between DNS policy and the
[`grayhaven-vault-example` hosted domain documentation](https://github.com/dean1012/grayhaven-vault-example/blob/main/docs/schema.md#hosted-domain-dns-coordination).

[Back to top](#dns)
