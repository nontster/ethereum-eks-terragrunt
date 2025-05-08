
locals {
    name_suffix          = var.environment_name != "prod" ? "-${var.environment_name}" : ""
    name_prefix          = var.name_prefix != "" ? "${var.name_prefix}-" : ""
    bucket_name   = "${local.name_prefix}${var.bucket_name}${local.name_suffix}"
}

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = local.bucket_name
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }

  tags = {
    Name        = local.bucket_name
    Environment = var.environment_name
  }
}