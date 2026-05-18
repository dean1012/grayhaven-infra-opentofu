locals {
  client_name = "grayhaven"
  environment = "prod"

  common_tags = [
    "client-${local.client_name}",
    "env-${local.environment}",
    "managed-by-opentofu"
  ]

  bastion_tags = concat(local.common_tags, [
    "project-sec",
    "role-bastion",
    "scope-grayhaven-sec-prod-bastion"
  ])

  web_tags = concat(local.common_tags, [
    "project-core",
    "role-web",
    "scope-grayhaven-core-prod-web"
  ])
}
