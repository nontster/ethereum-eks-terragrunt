# Include the root `terragrunt.hcl` configuration. The root configuration contains settings that are common across all
# components and environments, such as how to configure remote state.
include "root" {
  path = find_in_parent_folders("root.hcl") # Include common settings
}

# Configure the version of the module to use in this environment. This allows you to promote new versions one
# environment at a time (e.g., qa -> stage -> prod).
terraform {
  source = "${get_path_to_repo_root()}//modules/s3"  # Relative path to the module
}

locals {
  bucket_name = "ethereum-config"
  name_prefix = "domecloud"
}

inputs = {
  name_prefix = local.name_prefix
  bucket_name = local.bucket_name
}