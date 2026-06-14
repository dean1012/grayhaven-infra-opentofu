resource "digitalocean_firewall" "this" {
  name = var.name
  tags = var.target_tags

  dynamic "inbound_rule" {
    for_each = var.inbound_rules

    content {
      protocol                  = inbound_rule.value.protocol
      port_range                = inbound_rule.value.port_range
      source_addresses          = inbound_rule.value.source_addresses
      source_load_balancer_uids = inbound_rule.value.source_load_balancer_uids
      source_tags               = inbound_rule.value.source_tags
    }
  }

  dynamic "outbound_rule" {
    for_each = var.outbound_rules

    content {
      protocol              = outbound_rule.value.protocol
      port_range            = outbound_rule.value.port_range
      destination_addresses = outbound_rule.value.destination_addresses
      destination_tags      = outbound_rule.value.destination_tags
    }
  }
}
