variable "name" {
  description = "DigitalOcean VPC name"
  type        = string
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR range assigned to the VPC"
  type        = string
}

variable "description" {
  description = "DigitalOcean VPC description"
  type        = string
  default     = null
}
