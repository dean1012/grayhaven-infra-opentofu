locals {
  client_name = "grayhaven"
  environment = "prod"

  ssh_key_fingerprints = [
    "2e:7c:fa:e9:85:22:4d:1a:ca:e4:b0:6d:01:c5:36:ed"
  ]

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
