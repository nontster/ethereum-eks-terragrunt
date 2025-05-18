output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = module.eks.cluster_arn
}

output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = module.eks.cluster_id
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_version" {
  description = "Version of the EKS cluster"
  value       = module.eks.cluster_version
}

output "cluster_platform_version" {
  description = "Platform version of the EKS cluster"
  value       = module.eks.cluster_platform_version
}

output "cluster_status" {
  description = "Status of the EKS cluster"
  value       = module.eks.cluster_status
}

output "cluster_endpoint" {
  description = "Endpoint of the EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Certificate authority data for the EKS cluster"
  value       = module.eks.cluster_certificate_authority_data
}

# Optional: Output the role ARN for easy reference (e.g., for K8s manifests)
# output "s3_sync_iam_role_arn" {
#   description = "ARN of the IAM Role for S3 Sync Service Account"
#   value       = module.iam_assumable_role_s3_sync.iam_role_arn
# }

output "aws_efs_file_system_id" {
  description = "ID of the EFS file system"
  value       = aws_efs_file_system.this[0].id
}