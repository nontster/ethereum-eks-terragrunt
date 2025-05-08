# Include the root `terragrunt.hcl` configuration. The root configuration contains settings that are common across all
# components and environments, such as how to configure remote state.
include "root" {
  path = find_in_parent_folders("root.hcl") # Include common settings
}

# Configure the version of the module to use in this environment. This allows you to promote new versions one
# environment at a time (e.g., qa -> stage -> prod).
terraform {
  # Expose the base source URL so different versions of the module can be deployed in different environments.
  source = "${get_path_to_repo_root()}//modules/eks"  # Relative path to the module
}

dependencies {
  paths = ["../../../vpc"]
}

dependency "vpc" {
  config_path = "../../../vpc"  # Path to the AWS VPC Terragrunt module (relative)
}

locals {
  eks_cluster_name  = "ethereum"
  eks_cluster_version = "1.32"  # Specify the desired EKS version
}

inputs = {  
  eks_cluster_name    = local.eks_cluster_name
  eks_cluster_version = local.eks_cluster_version
  
  enable_aws_ebs_csi_driver_role = true  # Enable the AWS EBS CSI driver role
  enable_aws_efs_csi_driver_role = false # Enable the AWS EFS CSI driver role
  enable_aws_lbc_role = true  # Enable the AWS Load Balancer Controller role

  node_group_min_size = 2
  node_group_max_size = 5
  instance_types      = ["m6i.large"]  # Specify the desired instance types
  vpc_private_subnets = dependency.vpc.outputs.private_subnets
  vpc_id              = dependency.vpc.outputs.vpc_id

}