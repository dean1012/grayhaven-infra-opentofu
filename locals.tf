locals {
  client_name = "grayhaven"
  environment = "prod"

  common_tags = [
    "client-grayhaven",
    "project-core",
    "managed-by-opentofu"
  ]
}
