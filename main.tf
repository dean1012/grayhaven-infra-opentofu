module "vpc" {
  source = "./modules/vpc"

  name        = "${local.client_name}-core-${local.environment}-vpc"
  region      = var.default_region
  vpc_cidr    = var.default_vpc_cidr
  description = "Production VPC for Grayhaven Systems LLC"
}
