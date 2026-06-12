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

Edit the production values in these files, using the generated passphrases and
deploy key material from earlier sections where applicable:

- `config.yml`
- `vault/common.yml`
- `vault/bastion.yml`
- `vault/web.yml`

Encrypt the vault files with the production Ansible Vault passphrase, then
commit and push main to the new private GitHub repository. Create the new private
GitHub repository through GitHub's website before adding `origin` and pushing.

```bash
ansible-vault encrypt vault/common.yml vault/bastion.yml vault/web.yml
git add .
git commit -S -m "Initialize production vault data"
git remote add origin git@github.com:<owner>/<private-vault-repo>.git
git push -u origin main
```

Create the staging branch from the initialized main branch, then decrypt the
copied production vault files with the production Ansible Vault passphrase:

```bash
git switch -c staging
ansible-vault decrypt vault/common.yml vault/bastion.yml vault/web.yml
```

Edit the staging values in these files, using the generated passphrases and
deploy key material from earlier sections where applicable:

- `config.yml`
- `vault/common.yml`
- `vault/bastion.yml`
- `vault/web.yml`

Encrypt the vault files with the staging Ansible Vault passphrase, then commit
and push staging:

```bash
ansible-vault encrypt vault/common.yml vault/bastion.yml vault/web.yml
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
cp grayhaven.env.example "$HOME/.bashrc.d/grayhaven.env"
chmod 0600 "$HOME/.bashrc.d/grayhaven.env"
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
  if [ -n "${!var}" ]; then
    printf '%s=defined\n' "$var"
  else
    printf '%s=missing\n' "$var"
  fi
done
```

[Back to top](#setup)

## Edit Policy Files

Review and update the committed policy files before first deployment:

- `policy/compute.yml`
- `policy/dns.yml`
- `policy/ssh-keys.yml`
- `policy/firewall/staging.yml`
- `policy/firewall/prod.yml`

Policy file structure and change procedures are documented in
[Policy Files](policy.md).

[Back to top](#setup)
