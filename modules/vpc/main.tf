data "aws_availability_zones" "available" {
  filter {
    name   = "state"
    values = ["available"]
  }
}

locals {
  # Calculate subnet CIDRs based on the chosen AZs and base VPC CIDR
  # Note: The cidrsubnet function parameters (newbits, netnum) depend on the base VPC CIDR size.
  # These calculations assume a /16 base VPC CIDR. Adjust if necessary.
  # Private subnets: /20 blocks (assuming /16 base, 16+4=20)
  private_subnets_calculated = [for k, v in var.aws_availability_zones : cidrsubnet(var.vpc_cidr, 4, k)]
  # Public subnets: /24 blocks (assuming /16 base, 16+8=24), offset +48
  public_subnets_calculated = [for k, v in var.aws_availability_zones : cidrsubnet(var.vpc_cidr, 8, k + 48)]
  # Intra subnets: /24 blocks (assuming /16 base, 16+8=24), offset +52
  intra_subnets_calculated = [for k, v in var.aws_availability_zones : cidrsubnet(var.vpc_cidr, 8, k + 52)]


  # Determine the required boolean flags based on the nat_gateway_strategy input
  # Scenario 'none':         enable=false, single=false, per_az=false
  # Scenario 'single':       enable=true,  single=true,  per_az=false
  # Scenario 'per_az':        enable=true,  single=false, per_az=true
  # Scenario 'per_subnet':   enable=true,  single=false, per_az=false (this is the underlying module's default when enable=true)

  enable_nat_gateway     = var.nat_gateway_strategy != "none"
  single_nat_gateway     = var.nat_gateway_strategy == "single"
  one_nat_gateway_per_az = var.nat_gateway_strategy == "per_az"

  # Conditionally set intra_subnets to null if not enabled
  intra_subnets_final = var.enable_intra_subnets ? local.intra_subnets_calculated : []
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  # Pass variables from our module's inputs to the underlying module
  name = var.vpc_name
  cidr = var.vpc_cidr

  azs = var.aws_availability_zones
  #azs = local.azs
  private_subnets = local.private_subnets_calculated
  public_subnets  = local.public_subnets_calculated
  intra_subnets   = local.intra_subnets_final


  # Use the local variables derived from nat_gateway_strategy
  enable_nat_gateway     = local.enable_nat_gateway
  single_nat_gateway     = local.single_nat_gateway
  one_nat_gateway_per_az = local.one_nat_gateway_per_az

  # Pass through other variables
  enable_vpn_gateway = var.enable_vpn_gateway

  # Assign tags
  tags                = var.tags
  public_subnet_tags  = merge(var.public_subnet_tags, { "Name" = "${var.vpc_name}-public" })
  private_subnet_tags = merge(var.private_subnet_tags, { "Name" = "${var.vpc_name}-private" })
  # Only assign intra tags if subnets are created
  intra_subnet_tags = var.enable_intra_subnets ? var.intra_subnet_tags : null

  # Propagate tags to underlying resources (example, customize as needed)
  vpc_tags          = var.tags
  dhcp_options_tags = var.tags
}
