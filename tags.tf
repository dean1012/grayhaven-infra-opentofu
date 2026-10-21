resource "digitalocean_tag" "bastion_scope" {
  count = local.is_environment ? 1 : 0

  name = "scope-${local.client_name}-sec-${local.environment}-bastion"
}

resource "digitalocean_tag" "web_scope" {
  count = length(local.web_instances) > 0 ? 1 : 0

  name = "scope-${local.client_name}-core-${local.environment}-web"
}

resource "digitalocean_tag" "mcp_scope" {
  count = length(local.mcp_instances) > 0 ? 1 : 0
  name  = "scope-${local.client_name}-core-${local.environment}-mcp"
}
