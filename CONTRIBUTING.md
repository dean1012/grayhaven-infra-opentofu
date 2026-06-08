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

Initialize providers without configuring a backend:

```bash
tofu init -backend=false
```

[Back to top](#contributing)

## Validation

Run the same validation commands used by CI:

```bash
tofu fmt -check -recursive
tofu validate
shellcheck scripts/read-vault-config
git ls-files '*.yml' '*.yaml' | xargs -r yamllint
git ls-files '*.md' | xargs -r markdownlint-cli2
```

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

CI runs on pushes, pull requests, and manual workflow dispatches. Pull requests
are squash merged after CI passes and review conversations are resolved.

[Back to top](#contributing)

## Documentation Guidelines

Keep public documentation factual and operational. This repository demonstrates
how Grayhaven Systems LLC manages its own infrastructure; it is not a generic
deployment template.

Document safety boundaries, workspace assumptions, and non-obvious
implementation decisions. Avoid comments that merely restate straightforward
OpenTofu resources.

[Back to top](#contributing)
