module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.17.0"

  name = "${var.project}-${var.environment}-vpc"
  cidr = var.cidr_vpc

  azs             = [var.availability_zone_1, var.availability_zone_2, var.availability_zone_3]
  private_subnets = [var.private_subnets[0], var.private_subnets[1], var.private_subnets[2]]
  public_subnets  = [var.public_subnets[0], var.public_subnets[1], var.public_subnets[2]]

  enable_nat_gateway   = true
  enable_vpn_gateway   = false
  enable_dns_hostnames = false

  enable_ipv6 = false

}

resource "aws_eip" "bh" {
  instance = module.bh_instance.id
  vpc      = true
}
