locals {
  public_subnets = {
    for i, az in var.azs : "public-${az}" => {
      cidr_block = var.public_subnet_cidr_blocks[i]
      az         = az
    }
  }

  private_subnets = {
    for i, az in var.azs : "private-${az}" => {
      cidr_block = var.private_subnet_cidr_blocks[i]
      az         = az
    }
  }
}