output "bucket_arn" {
  value       = module.s3_bucket.s3_bucket_arn
  description = "The ARN of the S3 bucket"
}

output "bucket_name" {
  value       = module.s3_bucket.s3_bucket_id
  description = "The name of the S3 bucket"
}