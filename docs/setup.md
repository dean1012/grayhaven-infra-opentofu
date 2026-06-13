# Setup

This document describes the initialization and configuration that must be
completed before operating within this repository.

## Table of Contents

- [Generate Passphrases](#generate-passphrases)
- [Create a DigitalOcean Token](#create-a-digitalocean-token)
- [Generate Deploy Key Material](#generate-deploy-key-material)
- [Set Up the Vault Repository](#set-up-the-vault-repository)
- [Set Up the Environment](#set-up-the-environment)
- [Edit Policy Files](#edit-policy-files)
- [Validate Initialization & Configuration](#validate-initialization--configuration)

## Generate Passphrases

Generate strong passphrases for OpenTofu state encryption and Ansible Vault.
Use unique values for each workspace or environment.

```bash
openssl rand -hex 48
```

[Back to top](#setup)

## Create a DigitalOcean Token

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

Install `yamllint` on the workstation before enabling the hook. On AlmaLinux 10,
use a user-level Python install when `pip` is available:

```bash
python3 -m pip install --user yamllint
```

If `pip` is not available for the user account, enable EPEL and install the
operating system package instead:

```bash
sudo dnf install epel-release
sudo dnf install yamllint
```

Confirm the command is available:

```bash
command -v yamllint
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

Review and update all `policy/` files.

[Policy](policy.md) documentation details file formats for all policy files.

[Back to top](#setup)

## Validate Initialization & Configuration

Install local validation tools on the workstation:

```bash
sudo dnf install epel-release
sudo dnf install ShellCheck npm
npm config set prefix "$HOME/.local"
npm install --global markdownlint-cli2
export PATH="$HOME/.local/bin:$PATH"
```

Confirm the validation commands are available:

```bash
command -v shellcheck
command -v markdownlint-cli2
```

Run ShellCheck on tracked shell entrypoints in the infra checkout:

```bash
git grep -Il '^#!.*\(ba\)\?sh' -- . | xargs -r shellcheck
```

Run Markdownlint on all Markdown files in the infra checkout:

```bash
markdownlint-cli2 "**/*.md" "!.terraform/**"
```

[Back to top](#setup)
