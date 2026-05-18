variable "name" {
  description = "DigitalOcean droplet name"
  type        = string
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
}

variable "vpc_id" {
  description = "DigitalOcean VPC ID"
  type        = string
}

variable "ssh_key_fingerprints" {
  description = "SSH key fingerprints authorized for droplet access"
  type        = list(string)
}

variable "size" {
  description = "DigitalOcean droplet size"
  type        = string
}

variable "image" {
  description = "DigitalOcean operating system image"
  type        = string
}

variable "tags" {
  description = "DigitalOcean droplet tags"
  type        = list(string)
}
