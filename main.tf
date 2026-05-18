module "vpc" {
  source = "./modules/vpc"

  name        = "${local.client_name}-${local.project_name}-prod-vpc"
  region      = var.default_region
  vpc_cidr    = var.default_vpc_cidr
  description = "Production VPC for Grayhaven Systems LLC"
}
