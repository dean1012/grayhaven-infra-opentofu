# Setup

This document describes the first-time setup needed before running
`grayhaven-infra-opentofu`.

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

OpenTofu state encryption uses these environment variables:

- `TF_VAR_state_encryption_passphrase_baseline`
- `TF_VAR_state_encryption_passphrase_staging`
- `TF_VAR_state_encryption_passphrase_prod`

Ansible Vault uses these environment variables during fresh bastion bootstrap:

- `TF_VAR_grayhaven_vault_password_staging`
- `TF_VAR_grayhaven_vault_password_prod`

The actual vault files are maintained in the private vault repository. Use the
procedures documented in
[`grayhaven-vault-example`](https://github.com/dean1012/grayhaven-vault-example)
when encrypting, editing, or rekeying those files.

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

If DigitalOcean rejects an operation during validation or deployment, inspect
the denied resource/action and update the token scope deliberately.

[Back to top](#setup)

## Generate Deploy Key Material

Generate an SSH keypair for the Ansible deploy/control key. Store the private
key in a safe location under `$HOME` with restrictive ownership and
permissions.

```bash
ssh-keygen -t ed25519 -C "grayhaven-ansible-deploy"
chmod 0700 "$HOME/<safe-key-directory>"
chmod 0600 "$HOME/<safe-key-directory>/ansible-deploy.key"
chmod 0644 "$HOME/<safe-key-directory>/ansible-deploy.key.pub"
```

This key serves two purposes:

- GitHub deploy-key access to the private vault repository.
- Ansible control-node SSH access from bastion hosts to managed hosts.

Add the public key as a read-only deploy key on the private vault repository.
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

Edit `config.yml` and the files under `vault/` for the real environment, then
encrypt the vault files before committing. The expected file shapes, encryption
workflow, vault passphrase rotation, API token guidance, and deploy-key notes
are documented in
[`grayhaven-vault-example`](https://github.com/dean1012/grayhaven-vault-example).

Create a new private GitHub repository for the real vault, then commit and push
the initialized repository:

```bash
git add .
git commit -S -m "Initialize private vault repository"
git remote add origin git@github.com:<owner>/<private-vault-repo>.git
git branch -M main
git push -u origin main
git switch -c staging
git push -u origin staging
```

Add the deploy public key generated earlier as a read-only deploy key on the
new private vault repository.

[Back to top](#setup)

## Set Up the Environment

Copy the sample environment file into a private shell fragment:

```bash
mkdir -p "$HOME/.bashrc.d"
cp grayhaven.env.example "$HOME/.bashrc.d/grayhaven.env"
chmod 0600 "$HOME/.bashrc.d/grayhaven.env"
```

Edit `$HOME/.bashrc.d/grayhaven.env` with real values, then source the shell
configuration:

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

Fetch the vault refs before planning or applying:

```bash
git -C "$TF_VAR_grayhaven_vault_checkout_path" fetch origin main staging
```

OpenTofu reads `config.yml` from the workspace-selected Git ref in the local
vault checkout, not from the checkout's current branch.

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
