# Setup

This document describes the initialization and configuration that must be
completed before operating within this repository.

## Table of Contents

- [Install Dependencies](#install-dependencies)
- [Generate Passphrases](#generate-passphrases)
- [Create a DigitalOcean API Token](#create-a-digitalocean-api-token)
- [Generate Deploy Key Material](#generate-deploy-key-material)
- [Set Up the Vault Repository](#set-up-the-vault-repository)
- [Set Up the Environment](#set-up-the-environment)
- [Edit Policy Files](#edit-policy-files)
- [Validate Initialization & Configuration](#validate-initialization--configuration)
- [Deploy Initial Environments](#deploy-initial-environments)

## Install Dependencies

Install OpenTofu from the official OpenTofu DNF repository:

```bash
cat <<EOF | sudo tee /etc/yum.repos.d/opentofu.repo
[opentofu]
name=opentofu
baseurl=https://packages.opentofu.org/opentofu/tofu/rpm_any/rpm_any/\$basearch
repo_gpgcheck=0
gpgcheck=1
enabled=1
gpgkey=https://get.opentofu.org/opentofu.gpg https://packages.opentofu.org/opentofu/tofu/gpgkey
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
metadata_expire=300
EOF
sudo rpm --import https://get.opentofu.org/opentofu.gpg
sudo rpm --import https://packages.opentofu.org/opentofu/tofu/gpgkey
sudo dnf install -y tofu
```

Install Ansible, OpenSSL, and local validation tools on the workstation:

```bash
sudo dnf install epel-release
sudo dnf install ansible-core openssl python3-pip
python3 -m pip install --user --upgrade pip
python3 -m pip install --user yamllint
```

Confirm the required commands are available:

```bash
command -v tofu
command -v ansible-vault
command -v openssl
command -v yamllint
```

[Back to top](#setup)

## Generate Passphrases

Generate strong passphrases for OpenTofu state encryption and Ansible Vault.
Use unique values for each workspace or environment.

```bash
openssl rand -hex 48
```

[Back to top](#setup)

## Create a DigitalOcean API Token

Create a DigitalOcean API token for OpenTofu with the narrowest practical
scope for this automation.

| Resource Type | Permissions                         |
| ------------- | ----------------------------------- |
| actions       | read                                |
| certificate   | create, read, delete                |
| domain        | create, read, update, delete        |
| droplet       | create, read, update, delete, admin |
| firewall      | create, read, update, delete        |
| image         | read                                |
| load_balancer | create, read, update, delete        |
| monitoring    | create, read, update, delete        |
| project       | create, read, update, delete        |
| regions       | read                                |
| sizes         | read                                |
| snapshot      | read                                |
| ssh_key       | create, read, update, delete        |
| tag           | create, read, delete                |
| vpc           | create, read, update, delete        |

[Back to top](#setup)

## Generate Deploy Key Material

Generate an SSH keypair for read-only deploy-key access to the private vault
repository. Store the private key in a safe location under `$HOME` with
restrictive ownership and permissions.

```bash
mkdir -p "$HOME/<safe-key-directory>"
chmod 0700 "$HOME/<safe-key-directory>"
ssh-keygen -t ed25519 -C "grayhaven-vault-deploy" \
  -f "$HOME/<safe-key-directory>/ansible-deploy.key"
chmod 0600 "$HOME/<safe-key-directory>/ansible-deploy.key"
chmod 0644 "$HOME/<safe-key-directory>/ansible-deploy.key.pub"
```

Do not commit or print the private key.

[Back to top](#setup)

## Set Up the Vault Repository

Create a new private repository named `grayhaven-vault` on GitHub. In the
private repository settings, disable optional features that are not used for
vault operations: Wiki, issues, sponsorships, discussions, projects, and pull
request features when GitHub exposes a control for them.

Use
[`grayhaven-vault-example`](https://github.com/dean1012/grayhaven-vault-example)
as the documented starting shape for the private vault repository.

Example setup flow:

```bash
git clone git@github.com:dean1012/grayhaven-vault-example.git grayhaven-vault
cd grayhaven-vault
```

Remove the `.git` directory so the new private repository does not retain the
example repository history, then initialize a fresh repository:

```bash
git init
```

Install the provided pre-commit hook before the first commit. This hook rejects
commits when required vault files are missing or staged without Ansible Vault
encryption.

```bash
mkdir -p .githooks
cp ../grayhaven-infra-opentofu/templates/vault/pre-commit .githooks/pre-commit
chmod 0755 .githooks/pre-commit
git config core.hooksPath .githooks
```

Edit `config.yml` and the files under `vault/` for production and staging as
shown below. File formats are documented in detail in the
[`grayhaven-vault-example`](https://github.com/dean1012/grayhaven-vault-example)
repository.

Configure production first so the initial commit creates the `main` branch:

```bash
git branch -M main
```

Edit `config.yml` and the files under `vault/` using the generated production
values from above where applicable.

Encrypt the `vault/*.yml` files with the production Ansible Vault passphrase
generated above, then commit and push `main` to the new private GitHub
repository.

```bash
yamllint .
ansible-vault encrypt vault/*.yml
git add .
git commit -S -m "Initialize production vault data"
git remote add origin git@github.com:dean1012/grayhaven-vault.git
git push -u origin main
```

Create the staging branch from the initialized main branch, then decrypt the
copied production vault files with the production Ansible Vault passphrase:

```bash
git switch -c staging
ansible-vault decrypt vault/*.yml
```

Edit `config.yml` and the files under `vault/` using the generated staging
values from above where applicable.

Encrypt the `vault/*.yml` files with the staging Ansible Vault passphrase
generated above, then commit and push `staging` to the new private GitHub
repository.

```bash
yamllint .
ansible-vault encrypt vault/*.yml
git add .
git commit -S -m "Initialize staging vault data"
git push -u origin staging
```

Add the deploy public key generated earlier as a read-only deploy key on the
new private vault repository through GitHub's website.

[Back to top](#setup)

## Set Up the Environment

Copy the sample environment file into a private shell fragment:

```bash
mkdir -p "$HOME/.bashrc.d"
cp docs/examples/grayhaven.env.example "$HOME/.bashrc.d/grayhaven.env"
chmod 0600 "$HOME/.bashrc.d/grayhaven.env"
```

Ensure `$HOME/.bashrc` loads files from `$HOME/.bashrc.d`. Check for an
existing `.bashrc.d` block:

```bash
grep -n '\.bashrc\.d' "$HOME/.bashrc"
```

If no lines are returned, add this block to `$HOME/.bashrc`:

```bash
# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc
```

Edit `$HOME/.bashrc.d/grayhaven.env` using the generated values from above
where applicable, then source the shell configuration:

```bash
source "$HOME/.bashrc"
```

Validate that required variables are defined without printing their values:

```bash
for var in \
  TF_VAR_state_encryption_passphrase_baseline \
  TF_VAR_state_encryption_passphrase_staging \
  TF_VAR_state_encryption_passphrase_prod \
  TF_VAR_do_token \
  TF_VAR_grayhaven_vault_repo_url \
  TF_VAR_grayhaven_vault_checkout_path \
  TF_VAR_grayhaven_ansible_deploy_public_key \
  TF_VAR_grayhaven_ansible_deploy_private_key \
  TF_VAR_grayhaven_vault_password_staging \
  TF_VAR_grayhaven_vault_password_prod
do
  if [ -n "${!var:-}" ]; then
    printf '\033[32m%s=defined\033[0m\n' "$var"
  else
    printf '\033[31m%s=missing\033[0m\n' "$var"
  fi
done
```

[Back to top](#setup)

## Edit Policy Files

[Policy](policy.md) documentation details file formats for all policy files.
Please review our
[Infrastructure Naming & Tagging Conventions](naming-tagging-conventions.md)
before naming resources.

Review and update all `policy/baseline/` files setting values appropriate for
shared baseline resources. Baseline values should include shared DNS zones,
baseline-owned DNS records, and admin SSH keys.

After editing all `policy/baseline/` files, review and commit them:

```bash
git status --short policy/baseline/
git add policy/baseline/
git commit -S -m "Configure baseline policy files"
```

Review and update all `policy/staging/` files setting values appropriate for
staging.
Staging values should support short-lived validation deployments before
promotion to production.

After editing all `policy/staging/` files, review and commit them:

```bash
git status --short policy/staging/
git add policy/staging/
git commit -S -m "Configure staging policy files"
```

Review and update all `policy/prod/` files setting values appropriate for
production. Production values are the desired steady-state settings for the
long-lived `prod` workspace.

After editing all `policy/prod/` files, review and commit them:

```bash
git status --short policy/prod/
git add policy/prod/
git commit -S -m "Configure production policy files"
```

[Back to top](#setup)

## Validate Initialization & Configuration

Confirm the working tree is clean:

```bash
git status --short
```

No files should be listed. At this point, all intended setup changes should be
staged and committed.

Check OpenTofu formatting in the infra checkout:

```bash
tofu fmt -check -recursive
```

Run Yamllint on YAML files in the infra checkout:

```bash
yamllint .
```

[Back to top](#setup)

## Deploy Initial Environments

Initialize OpenTofu once from the repository root:

```bash
tofu init
```

Deploy baseline first so shared protected resources exist before environment
runtime resources:

```bash
tofu workspace new baseline
tofu plan
tofu apply
```

Deploy staging next and validate it before production:

```bash
tofu workspace new staging
tofu plan
tofu apply
```

Deploy production after staging review is complete:

```bash
tofu workspace new prod
tofu plan
tofu apply
```

Review [Workspaces](workspaces.md), [Operations](operations.md),
[Safety](safety.md), and [Troubleshooting](troubleshooting.md) documentation
for further information.

[Back to top](#setup)
