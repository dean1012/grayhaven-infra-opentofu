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
