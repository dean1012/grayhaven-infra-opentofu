# OpenTofu Test Suite

This document describes the offline OpenTofu test suite for this repository.

## Table of Contents

- [Purpose](#purpose)
- [How Tests Run](#how-tests-run)
- [Test Policy Fixtures](#test-policy-fixtures)
- [What Is Tested](#what-is-tested)
- [Limitations](#limitations)
- [Local Use](#local-use)

## Purpose

The OpenTofu tests provide offline plan-shape validation. They verify that
committed policy files and static test fixtures produce the expected resource
graph for the supported workspaces without deploying infrastructure.

The suite is intended to catch regressions in workspace ownership, DNS
expansion, compute scaling behavior, TLS mode selection, and admin SSH key
attachment before a change reaches a live `tofu plan` or `tofu apply`.

[Back to top](#opentofu-test-suite)

## How Tests Run

CI runs OpenTofu validation in two jobs:

- `Validate`: runs formatting, static validation, YAML linting, Markdown
  linting, ShellCheck, and GitHub Actions linting.
- `Offline Plan Tests`: runs `tofu test` against `baseline`, `staging`, and
  `prod` from a backend-disabled checkout.

The OpenTofu test job initializes with `tofu init -backend=false`, creates a
temporary local workspace for each supported workspace, and runs the matching
test file:

- `tests/baseline.tftest.hcl`
- `tests/staging.tftest.hcl`
- `tests/prod.tftest.hcl`

The test files use mocked providers, fake sensitive values, and
`refresh = false` plans. The external vault-config lookup is mocked for
environment tests so the suite does not need access to the private vault
repository. The mocked vault lookup returns both `config.yml` and
`firewall.yml` content.

[Back to top](#opentofu-test-suite)

## Test Policy Fixtures

The test suite uses optional policy path overrides to load static fixture files
from `tests/fixtures/`:

- `grayhaven_test_compute_policy_path`
- `grayhaven_test_dns_policy_path`
- `grayhaven_test_ssh_keys_policy_path`

These variables exist only for offline plan tests and disposable validation
checkouts. Leave them unset for operational deployments.

[Back to top](#opentofu-test-suite)

## What Is Tested

Baseline tests verify that the `baseline` workspace plans shared resources
under baseline ownership:

- the shared DigitalOcean project;
- managed DNS zones;
- protected shared DNS records, including mail records;
- the protected baseline VPC;
- admin SSH key resources.

Baseline fixture tests also verify support for unprotected A, CNAME, and TXT
records under `records`, and verify that unsupported DNS record types are
rejected by the DNS policy guard.

DNS fixture tests use the test-only DNS policy override to verify baseline
unprotected records, environment explicit records, unsupported DNS record
rejection, apex-only environment records, and invalid environment alias
combinations.

Staging and production tests verify committed policy plans for their matching
workspaces, plus fixed scenario fixtures:

- 1 bastion / 1 web host with `auto` TLS resolving to host TLS;
- 2 bastions / 2 web hosts with `auto` TLS resolving to load-balancer TLS;
- 3 bastions / 3 web hosts with explicit load-balancer TLS;
- control bastion selection for each scaling fixture;
- environment DNS records for apex, `www`, and `dev`;
- explicit environment DNS `records` and `protected_records`;
- apex-only DNS behavior when aliases are disabled;
- validation that web aliases require an apex record;
- load-balancer certificate domain name ordering;
- admin SSH key lookup and droplet attachment.

Environment tests also verify that staging and production do not plan baseline
DNS resources. This keeps shared DNS ownership in `baseline` and runtime DNS
ownership in the environment workspaces.

[Back to top](#opentofu-test-suite)

## Limitations

The tests do not deploy resources and do not contact DigitalOcean. They cannot
prove provider availability, API permissions, quota availability, DNS
propagation, certificate issuance, SSH access, cloud-init execution, or
Ansible convergence.

The suite validates create/update plan shape. It does not prove destroy
behavior or live migration behavior for existing state.

The suite uses static fixtures and mocked provider defaults. It is designed to
catch repository logic regressions, not to replace live staging validation.

[Back to top](#opentofu-test-suite)

## Local Use

Local test execution should happen from a temporary state-free copy, not from
the operational checkout used for real deployments. The full local validation
workflow is documented in [CONTRIBUTING.md](../CONTRIBUTING.md).

For a targeted test run from a temporary validation checkout, select the
matching workspace before running the test file:

```bash
tofu init -backend=false

tofu workspace new baseline
tofu test -filter=tests/baseline.tftest.hcl -no-color

tofu workspace new staging
tofu test -filter=tests/staging.tftest.hcl -no-color

tofu workspace new prod
tofu test -filter=tests/prod.tftest.hcl -no-color
```

[Back to top](#opentofu-test-suite)
