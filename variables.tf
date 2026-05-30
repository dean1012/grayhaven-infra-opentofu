variable "state_encryption_passphrase" {
  description = "Passphrase used for local OpenTofu state encryption"
  type        = string
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

variable "default_vpc_cidr" {
  description = "CIDR range for the project VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "grayhaven_root_password_hash" {
  description = "Password hash for the root account used during bootstrap."
  type        = string
  sensitive   = true
}

variable "grayhaven_ansible_control_public_key" {
  description = "Public key for the Ansible automation user."
  type        = string
  sensitive   = true
}

variable "grayhaven_ansible_control_private_key" {
  description = "Private key for the Ansible automation user, installed only on bastion hosts."
  type        = string
  sensitive   = true
}

variable "grayhaven_discord_webhook_url" {
  description = "Discord webhook URL used by bastion hosts for notifications."
  type        = string
  sensitive   = true
}

variable "grayhaven_dev_basic_auth_htpasswd_line" {
  description = "htpasswd line used by web hosts for development HTTP basic authentication."
  type        = string
  sensitive   = true
}

variable "grayhaven_digitalocean_dns_api_token" {
  description = "DigitalOcean API token used by web hosts for DNS-01 certificate automation."
  type        = string
  sensitive   = true
}

variable "grayhaven_digitalocean_inventory_api_token" {
  description = "DigitalOcean API token used by bastion hosts for Ansible dynamic inventory."
  type        = string
  sensitive   = true
}
