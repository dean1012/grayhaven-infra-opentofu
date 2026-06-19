variable "state_encryption_passphrase_baseline" {
  description = "Passphrase used for local OpenTofu state encryption in the baseline workspace."
  type        = string
  sensitive   = true
}

variable "state_encryption_passphrase_staging" {
  description = "Passphrase used for local OpenTofu state encryption in the staging workspace."
  type        = string
  sensitive   = true
}

variable "state_encryption_passphrase_prod" {
  description = "Passphrase used for local OpenTofu state encryption in the prod workspace."
  type        = string
  sensitive   = true
}

variable "state_encryption_previous_passphrase_baseline" {
  description = "Previous baseline workspace state encryption passphrase used only during OpenTofu state passphrase rotation."
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
}

variable "state_encryption_previous_passphrase_staging" {
  description = "Previous staging workspace state encryption passphrase used only during OpenTofu state passphrase rotation."
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
}

variable "state_encryption_previous_passphrase_prod" {
  description = "Previous prod workspace state encryption passphrase used only during OpenTofu state passphrase rotation."
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
}

variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "default_region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc3"
}

variable "default_os_image" {
  description = "Operating system image"
  type        = string
  default     = "almalinux-10-x64"
}

variable "default_droplet_size" {
  description = "DigitalOcean droplet size"
  type        = string
  default     = "s-1vcpu-1gb"
}

variable "baseline_vpc_cidr" {
  description = "CIDR range for the baseline default VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "grayhaven_config_repo_ref" {
  description = "Git ref used by staging cloud-init and the bastion runner when checking out grayhaven-config-ansible. Production always uses main."
  type        = string
  default     = "main"

  validation {
    condition     = can(regex("^[A-Za-z0-9._/-]+$", var.grayhaven_config_repo_ref)) && !strcontains(var.grayhaven_config_repo_ref, "..")
    error_message = "grayhaven_config_repo_ref must be a simple Git ref containing only letters, numbers, dots, underscores, hyphens, and slashes."
  }
}

variable "grayhaven_test_compute_policy_path" {
  description = "Optional compute policy file path override for offline plan tests. Leave unset for operational deployments."
  type        = string
  default     = null
  nullable    = true
}

variable "grayhaven_test_dns_policy_path" {
  description = "Optional DNS policy file path override for offline plan tests. Leave unset for operational deployments."
  type        = string
  default     = null
  nullable    = true
}

variable "grayhaven_test_ssh_keys_policy_path" {
  description = "Optional admin SSH keys policy file path override for offline plan tests. Leave unset for operational deployments."
  type        = string
  default     = null
  nullable    = true
}

variable "grayhaven_test_firewall_policy_path" {
  description = "Optional firewall policy file path override for offline plan tests. Leave unset for operational deployments."
  type        = string
  default     = null
  nullable    = true
}

variable "grayhaven_test_vault_config_path" {
  description = "Optional vault config.yml file path override for offline plan tests. Leave unset for operational deployments."
  type        = string
  default     = null
  nullable    = true
}

variable "grayhaven_vault_repo_url" {
  description = "SSH URL for the private grayhaven-vault repository used by bastion hosts."
  type        = string
  default     = "git@github.com:dean1012/grayhaven-vault.git"
}

variable "grayhaven_vault_checkout_path" {
  description = "Local checkout path for grayhaven-vault. OpenTofu reads config.yml and firewall.yml from this checkout."
  type        = string
  default     = null
  nullable    = true
}

variable "grayhaven_vault_password_staging" {
  description = "Ansible Vault password used by staging bastion hosts to decrypt grayhaven-vault files."
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
}

variable "grayhaven_vault_password_prod" {
  description = "Ansible Vault password used by production bastion hosts to decrypt grayhaven-vault files."
  type        = string
  default     = null
  nullable    = true
  sensitive   = true
}

variable "grayhaven_ansible_deploy_public_key" {
  description = "Public half of the bootstrap deployment key used for first-boot automation and GitHub deploy access."
  type        = string
  sensitive   = true
}

variable "grayhaven_ansible_deploy_private_key" {
  description = "Private half of the bootstrap deployment key used for first-boot automation and GitHub deploy access, installed only on bastion hosts."
  type        = string
  sensitive   = true
}
