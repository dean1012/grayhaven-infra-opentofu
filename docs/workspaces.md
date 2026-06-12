# Workspace Operations

[Return to README](../README.md)

Grayhaven infrastructure uses OpenTofu workspaces to separate shared baseline
resources from environment-specific runtime infrastructure.

## Table of Contents

- [Supported Workspaces](#supported-workspaces)
- [Routine Workflow](#routine-workflow)
- [Baseline Operations](#baseline-operations)
- [Staging Operations](#staging-operations)
- [Production Operations](#production-operations)
- [Destroy Operations](#destroy-operations)
- [Policy Management](#policy-management)
- [DNS Management](#dns-management)
- [Admin SSH Key Management](#admin-ssh-key-management)
- [Active Control Bastion Changes](#active-control-bastion-changes)
- [TLS Mode Changes](#tls-mode-changes)
- [Certificate Selectors](#certificate-selectors)
- [Secret Rotation](#secret-rotation)
- [State Safety](#state-safety)

## Supported Workspaces

The supported workspaces are:

- `baseline`
- `staging`
- `prod`

The `baseline` workspace manages shared resources that staging and production
depend on, including the DigitalOcean project, admin SSH keys, DNS zones, mail
DNS records, CAA records, and the default VPC.

The default VPC is named `grayhaven-core-baseline-vpc` and is managed as a
dedicated baseline resource instead of using the environment VPC module. It is
a non-runtime safety VPC and must survive accidental baseline destroy attempts.
Environment droplets are explicitly assigned to non-default environment VPCs.

The `staging` and `prod` workspaces manage environment-specific VPCs, droplets,
firewalls, web DNS records, droplet DNS records, and load balancers when the
compute policy requires them.

[Back to top](#workspace-operations)

## Routine Workflow

Routine deployment is intentionally plan-first. Select the workspace, review
the plan, and apply only after the proposed changes are understood:

```bash
tofu workspace select staging
tofu plan
tofu apply
```

For staging and production, the approved `tofu apply` is the single command
that carries the environment from infrastructure provisioning through
configuration convergence. It provisions DigitalOcean resources, renders
cloud-init for each droplet, bootstraps hosts into
[`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible),
and starts full Ansible convergence from the active control bastion.

When testing a feature branch or policy override, include the same variables in
both the plan and apply commands:

```bash
tofu workspace select staging
tofu plan -var 'grayhaven_config_repo_ref=<branch-name>'
tofu apply -var 'grayhaven_config_repo_ref=<branch-name>'
```

Keep terminal output private when plans may contain sensitive values. Do not
commit generated state, plan files, or local environment files.

[Back to top](#workspace-operations)

## Baseline Operations

Select the baseline workspace before managing shared resources:

```bash
tofu workspace select baseline
tofu plan
tofu apply
```

The baseline workspace must exist before staging or production can be applied
from an empty DigitalOcean account, because environment workspaces discover the
shared project and DNS zones created by baseline.

Do not destroy the `baseline` workspace. Staging and production depend on the
shared resources it manages, and destroying baseline can cause production
outages for mail and HTTPS services.

[Back to top](#workspace-operations)

## Staging Operations

Select the staging workspace before deploying test infrastructure:

```bash
tofu workspace select staging
tofu plan
tofu apply
```

Staging website records use the `staging.<domain>` DNS namespace. Staging reads
`config.yml` from the `staging` Git ref in the local `grayhaven-vault`
checkout. The vault checkout does not need to have `staging` checked out, but
the ref must be present locally.

Staging defaults to the `main` branch of
[`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible),
but it can test a specific config branch on a fresh deployment:

```bash
tofu plan -var 'grayhaven_config_repo_ref=<branch-name>'
tofu apply -var 'grayhaven_config_repo_ref=<branch-name>'
```

Staging can also test infrastructure policy files from an infra feature branch:

```bash
tofu plan -var 'grayhaven_infra_policy_repo_ref=<branch-name>'
tofu apply -var 'grayhaven_infra_policy_repo_ref=<branch-name>'
```

Branch/ref overrides are fresh-deployment controls. Avoid changing them on an
existing environment unless the purpose is to test that exact transition.

[Back to top](#workspace-operations)

## Production Operations

Select the production workspace before managing production infrastructure:

```bash
tofu workspace select prod
tofu plan
tofu apply
```

Production website records use the apex, `www`, and `dev` hostnames for each
managed domain. Production reads `main` from both
[`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
and the private `grayhaven-vault` repository. For vault selectors, OpenTofu
reads `config.yml` from the `main` Git ref in the local vault checkout.

Review production plans carefully before applying. Production applies should be
deliberate, and live certificate issuance should only happen when the vault
selector and TLS mode are intentionally set for that behavior.

[Back to top](#workspace-operations)

## Destroy Operations

Destroy environment workspaces only after selecting the intended workspace:

```bash
tofu workspace select staging
tofu plan -destroy
tofu destroy
```

Use destroy for staging cleanup after validation. Do not use destroy against
`baseline`. Baseline resources have OpenTofu destroy protection, but operators
should still treat baseline destruction as out of bounds.

After destroying staging, select `baseline` or another expected workspace so a
future command does not accidentally run in a stale environment context.

[Back to top](#workspace-operations)

## Policy Management

Committed policy files define environment behavior:

- `policy/compute.yml`
- `policy/dns.yml`
- `policy/ssh-keys.yml`
- `policy/firewall/staging.yml`
- `policy/firewall/prod.yml`

The compute policy declares bastion instances, web instances, the active
control bastion, and web TLS mode. Changing the active control bastion changes
the `bastion.*` DNS record and the tags used by Ansible to identify the runner
host.

The firewall policy files drive DigitalOcean hardware firewalls in this
repository and local firewalld policy in
[`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible).
When changing firewall policy, validate both cloud and host-level behavior.

[Back to top](#workspace-operations)

## DNS Management

`policy/dns.yml` defines managed DNS zones, baseline-owned records, and which
domains receive computed environment DNS records. The baseline workspace owns
DNS zones and shared records such as MX, SPF, DKIM, DMARC, and CAA records.

Use `protected_records` for records that must not be destroyed casually. Those
resources use OpenTofu destroy protection and must not be moved into staging or
production state. Use `records` only for baseline-owned records that may be
destroyed by a normal baseline plan when removed from policy.

DNS record creation is intentionally ordered by record type. Computed
environment records are created first, with A records before CNAME records.
Baseline `protected_records` are created next in A, CNAME, MX, TXT, and CAA
order. Baseline `records` are created after protected records and support only
A, CNAME, and TXT records. Put MX and CAA records in `protected_records`.

The implementation filters the DNS policy records by supported type before
creating the type-specific resource groups. This is O(k*n), where `k` is the
fixed number of supported DNS record types, so it reduces to O(n). The expected
DNS policy dataset is small enough that this is an acceptable real-world
tradeoff for clearer ordering and safer applies.

Staging and production own only computed environment DNS records for domains
marked under `environment`:

- `environment.apex: true` creates `staging.<domain>` in `staging` and
  `<domain>` in `prod`.
- `environment.web_aliases: true` creates `www.staging.<domain>` and
  `dev.staging.<domain>` in `staging`, or `www.<domain>` and `dev.<domain>`
  in `prod`.

Both fields default to false when omitted. `environment.web_aliases` requires
`environment.apex`; valid combinations are true/true, true/false, and
false/false. If both fields are false or omitted, staging and production create
no computed environment DNS records for that domain. The domain can still have
baseline-owned records from `protected_records` or `records`.

For hosted web domains, keep
[`grayhaven-vault-example`](https://github.com/dean1012/grayhaven-vault-example)
`hosted_domains` data and `policy/dns.yml` aligned: each hosted domain should
set both `environment.apex: true` and `environment.web_aliases: true`, and each
domain with both fields set to true should have matching `hosted_domains` data
so
[`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
can converge the corresponding vhosts.

To add a hosted domain:

1. Add the domain to `policy/dns.yml`.
2. Add required baseline shared records under `protected_records`.
3. Add optional baseline records that do not need destroy protection under
   `records`.
4. Set `environment.apex: true` when staging and production should manage the
   environment apex record for the domain.
5. Set `environment.web_aliases: true` only when the domain is a hosted web
   domain that should also receive `www` and `dev` aliases.
6. Run `tofu plan` in `baseline` and review the shared DNS additions.
7. Run `tofu plan` in `staging` or `prod` and review only environment DNS
   additions.
8. Update the `hosted_domains` contract documented in
   [`grayhaven-vault-example`](https://github.com/dean1012/grayhaven-vault-example)
   so [`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
   can converge the matching vhosts.

[Back to top](#workspace-operations)

## Admin SSH Key Management

`policy/ssh-keys.yml` defines admin SSH public keys under `admin_ssh_keys`.
Each entry uses a stable internal key and includes:

- `title`: the human-readable label and DigitalOcean SSH key name.
- `public_key`: the public SSH key material.

The baseline workspace creates and manages the DigitalOcean SSH key resources.
Staging and production look up those baseline-managed keys by `title` and
attach every configured admin key to every bastion and web droplet.

To add or remove an admin key:

1. Update `policy/ssh-keys.yml`.
2. Select `baseline`.
3. Run `tofu plan` and confirm only the intended SSH key resources change.
4. Run `tofu apply`.
5. Select `staging` or `prod`.
6. Run `tofu plan` and confirm droplets will receive the expected admin key
   fingerprints.
7. Apply the environment only when the droplet SSH key change is intended for
   that environment.

Public SSH keys are safe to commit. Private SSH keys and agent material must
never be committed or printed in terminal output.

[Back to top](#workspace-operations)

## Active Control Bastion Changes

The active control bastion is selected with `bastions.control_node` in
`policy/compute.yml`. Only that bastion receives the `control-node` tag and
runs the scheduled Ansible runner and poller.

To switch the active control bastion:

1. Ensure the target bastion exists in `policy/compute.yml`.
2. Change `bastions.control_node` to the target bastion key.
3. Select the target workspace and run `tofu plan`.
4. Confirm the plan only changes the expected DNS/tag relationships.
5. Run `tofu apply`.
6. SSH to the new `bastion.*` target and start a manual config run:

```bash
sudo systemctl start grayhaven-ansible-runner.service
```

After convergence, verify the runner and poller timers are enabled only on the
new control bastion. Existing non-control bastions remain SSH jump points.

[Back to top](#workspace-operations)

## TLS Mode Changes

Web TLS behavior is selected by `web.tls_mode` in `policy/compute.yml`:

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

[Back to top](#workspace-operations)

## Certificate Selectors

`grayhaven-vault/config.yml` contains the `certificate_environment` selector.
OpenTofu reads that selector from the workspace-selected Git ref in the local
vault checkout:

- `staging`: `staging:config.yml`
- `prod`: `main:config.yml`

The checked-out vault branch does not affect selector loading. Fetch the
expected refs before planning or applying:

```bash
git -C ../grayhaven-vault fetch origin main staging
```

In host TLS mode:

- `staging` uses Let's Encrypt staging through Certbot DNS-01.
- `production` uses live Let's Encrypt through Certbot DNS-01.

In load balancer TLS mode:

- `staging` uses a self-signed custom certificate on the DigitalOcean load
  balancer.
- `production` uses a DigitalOcean-managed live Let's Encrypt certificate on
  the load balancer.

The `grayhaven_certificate_environment` OpenTofu variable can force a
certificate environment during a fresh test deployment:

```bash
tofu plan -var 'grayhaven_certificate_environment=staging'
tofu apply -var 'grayhaven_certificate_environment=staging'
```

Deployment overrides are for fresh test deployments only. Changing overrides on
existing environments is undefined operational behavior and is not recommended.

[Back to top](#workspace-operations)

## Secret Rotation

Rotate secrets deliberately, one workspace or secret class at a time. Before
any rotation, confirm no other OpenTofu run or Ansible maintenance playbook is
active, back up local encrypted state, and keep all terminal output private.

### OpenTofu State Encryption Passphrases

State encryption passphrases are workspace-specific:

- `TF_VAR_state_encryption_passphrase_baseline`
- `TF_VAR_state_encryption_passphrase_staging`
- `TF_VAR_state_encryption_passphrase_prod`

To rotate one workspace state passphrase:

1. Back up the target workspace state and keep the backup private.
2. Export the old passphrase as the matching previous-passphrase variable:
   `TF_VAR_state_encryption_previous_passphrase_<workspace>`.
3. Export the new passphrase as
   `TF_VAR_state_encryption_passphrase_<workspace>`.
4. Select the target workspace.
5. Run `tofu plan` and confirm OpenTofu can read the existing state through
   the fallback method.
6. Run `tofu apply` so OpenTofu writes state with the new passphrase.
7. Unset and remove the previous-passphrase variable from the local shell
   configuration.
8. Run `tofu plan` again with only the new passphrase defined.

Do not remove or unset the previous passphrase until the apply has completed
and a follow-up plan succeeds with only the new passphrase.

### Ansible Vault Passphrases

Fresh bastion bootstrap receives the Ansible Vault password from:

- `TF_VAR_grayhaven_vault_password_staging`
- `TF_VAR_grayhaven_vault_password_prod`

When rotating an Ansible Vault passphrase, update the encrypted vault files
with `ansible-vault rekey`, update the matching OpenTofu environment variable
for future deployments, then rotate the persisted password on already deployed
bastions with
[`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
`playbooks/rotate-vault-password.yml`. Verify a manual runner invocation can
decrypt the vault after the rotation.

### DigitalOcean API Token

Create a replacement token with the documented scope, update
`TF_VAR_do_token`, then run a read-only `tofu plan` in `baseline`, `staging`,
and `prod` as applicable. Revoke the old token only after the new token can
plan the required workspaces.

### Deploy And Control Key Material

The deploy/control key is supplied to fresh droplets through
`TF_VAR_grayhaven_ansible_deploy_public_key` and
`TF_VAR_grayhaven_ansible_deploy_private_key`. For deployed bastions, rotate
the persisted key with
[`grayhaven-config-ansible`](https://github.com/dean1012/grayhaven-config-ansible)
`playbooks/rotate-vault-deploy-key.yml`, then update the OpenTofu variables so
future droplets receive the new key during bootstrap.

### Admin SSH Keys

Admin SSH private keys are outside this repository. To rotate admin access,
add the new public key to `policy/ssh-keys.yml`, apply `baseline`, apply the
target environment so droplets receive the new key, verify access, then remove
the old public key from policy and repeat the baseline/environment plan-first
workflow.

[Back to top](#workspace-operations)

## State Safety

Baseline resources are configured with OpenTofu destroy protection so accidental
baseline destroy attempts fail before removing shared resources.

State is encrypted locally through the workspace-specific OpenTofu state
encryption passphrase. Keep state backups private and do not commit them.

Offline `tofu test` validation should run from a temporary state-free copy, not
from the operational checkout used for real plan/apply work. The tests create
temporary local workspaces with mocked providers and do not replace live
workspace planning, drift review, staging deployment, or destroy procedures.

Recommended state handling:

- Keep `TF_VAR_state_encryption_passphrase_baseline`,
  `TF_VAR_state_encryption_passphrase_staging`, and
  `TF_VAR_state_encryption_passphrase_prod` out of shell history and committed
  files.
- Keep `terraform.tfstate*`, `terraform.tfstate.d/`, `.state-backups/`, and
  plan files private.
- Back up local state before large refactors or provider upgrades.
- Review plans before applying policy, DNS, load balancer, or certificate
  changes.

[Back to top](#workspace-operations)
