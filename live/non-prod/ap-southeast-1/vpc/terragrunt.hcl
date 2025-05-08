# Include the root `terragrunt.hcl` configuration. The root configuration contains settings that are common across all
# components and environments, such as how to configure remote state.
include "root" {
  path = find_in_parent_folders("root.hcl") # Include common settings
}

# Configure the version of the module to use in this environment. This allows you to promote new versions one
# environment at a time (e.g., qa -> stage -> prod).
terraform {
  source = "${get_path_to_repo_root()}//modules/vpc"  # Relative path to the module
}

locals {  
  vpc_name = "ethereum-vpc"
  vpc_cidr = "10.0.0.0/16"
  aws_availability_zones = ["ap-southeast-1a", "ap-southeast-1b"]
}

inputs = {
  vpc_name = local.vpc_name
  vpc_cidr = local.vpc_cidr

  aws_availability_zones = local.aws_availability_zones
  
  # Specify if intra subnets are needed for dev
  enable_intra_subnets = false

# Specify the desired NAT Gateway scenario
  nat_gateway_strategy = "single"  # Example: Use a single NAT GW for dev (cost saving)

  enable_vpn_gateway = false

  tags = {
    "Name"        = "ethereum-vpc"
    "Environment" = "non-prod"
    "Project"     = "Ethereum"
    "ManagedBy"   = "Terragrunt"
  }
}