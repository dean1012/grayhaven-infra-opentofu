variable "name" {
  description = "DigitalOcean firewall name"
  type        = string
}

variable "target_tags" {
  description = "DigitalOcean tags targeted by the firewall"
  type        = list(string)
}

variable "inbound_rules" {
  description = "Inbound firewall rules"
  type = list(object({
    protocol                  = string
    port_range                = string
    source_addresses          = optional(list(string), [])
    source_load_balancer_uids = optional(list(string), [])
    source_tags               = optional(list(string), [])
  }))
}

variable "outbound_rules" {
  description = "Outbound firewall rules"
  type = list(object({
    protocol              = string
    port_range            = string
    destination_addresses = optional(list(string), [])
    destination_tags      = optional(list(string), [])
  }))
}
