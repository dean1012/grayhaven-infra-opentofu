# Contributing

Thank you for your interest in improving `grayhaven-infra-opentofu`.

## Table of Contents

- [Development Setup](#development-setup)
- [Validation](#validation)
- [Pull Requests](#pull-requests)
- [Documentation Guidelines](#documentation-guidelines)

## Development Setup

Install OpenTofu and the validation tools used by CI:

```bash
python3 -m pip install --upgrade pip
python3 -m pip install yamllint
npm install --global markdownlint-cli2
```

Do not run `tofu init -backend=false` directly in the operational checkout
before real plan/apply work. Backend-disabled initialization is safe in CI's
ephemeral checkout, but local validation should use a temporary state-free copy
so the real `.terraform/` directory and encrypted local state context are not
disturbed.

The validation section includes a local temp-copy workflow.

[Back to top](#contributing)

## Validation

Run static checks from the repository root:

```bash
tofu fmt -check -recursive
shellcheck scripts/read-vault-config
git ls-files '*.yml' '*.yaml' | xargs -r yamllint
markdownlint-cli2 "**/*.md" "!.terraform/**"
```

Run OpenTofu validation and offline plan tests from a temporary state-free copy:

```bash
tmpdir="$(mktemp -d /tmp/grayhaven-infra-validate.XXXXXX)"
trap 'rm -rf "$tmpdir"' EXIT

rsync -a \
  --exclude '.git' \
  --exclude '.terraform' \
  --exclude 'terraform.tfstate*' \
  --exclude 'terraform.tfstate.d' \
  --exclude '.state-backups' \
  ./ "$tmpdir"/

cd "$tmpdir"
tofu init -backend=false
tofu validate

export TF_VAR_state_encryption_passphrase_baseline='offline-test-baseline-state-passphrase'
export TF_VAR_state_encryption_passphrase_staging='offline-test-staging-state-passphrase'
export TF_VAR_state_encryption_passphrase_prod='offline-test-prod-state-passphrase'

tofu workspace new baseline
tofu test -filter=tests/baseline.tftest.hcl -no-color

tofu workspace new staging
tofu test -filter=tests/staging.tftest.hcl -no-color

tofu workspace new prod
tofu test -filter=tests/prod.tftest.hcl -no-color
```

The `tofu test` suite is offline plan-shape validation. It uses mocked
providers, fake sensitive values, and refresh-disabled plans. It does not
deploy resources, validate live DigitalOcean behavior, check drift, or prove
destroy behavior.

The DNS tests include a test-only DNS policy fixture through
`grayhaven_test_dns_policy_path`. Leave that variable unset for operational
deployments.

Before committing changes, also check the current diff for whitespace errors:

```bash
git diff --check
```

[Back to top](#contributing)

## Pull Requests

Create a focused feature branch for each change. Reference the related issue in
each commit and include `Closes #<issue-number>` in the pull request
description when the pull request should close an issue after merging.

Sign each commit so GitHub can verify its authorship. The `main` branch ruleset
requires signed commits before merging:

```bash
git commit -S -m "<message> (Refs #<issue-number>)"
```

CI and OpenTofu plan tests run on pushes, pull requests, and manual workflow
dispatches. Pull requests are squash merged after the `Validate` and `Offline
Plan Tests` checks pass and review conversations are resolved.

[Back to top](#contributing)

## Documentation Guidelines

Keep public documentation factual and operational. This repository demonstrates
how Grayhaven Systems LLC manages its own infrastructure; it is not a generic
deployment template.

Document safety boundaries, workspace assumptions, and non-obvious
implementation decisions. Avoid comments that merely restate straightforward
OpenTofu resources.

[Back to top](#contributing)
