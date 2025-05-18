variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment_name" {
  description = "Environment name (e.g. dev, staging, prod)"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "" 
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "eks_cluster_version" {
  description = "EKS cluster version"
  type        = string 
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_private_subnets" {
  description = "List of private subnet IDs"
  type        = list(string)
}

variable "node_group_min_size" {
  description = "Minimum size of the node group"
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Maximum size of the node group"
  type        = number
  default     = 5
}

variable "instance_types" {
  description = "List of instance types for the node group"
  type        = list(string)
  default     = ["m6i.large"]
}

variable "ami_type" {
  description = "AMI type for the node group"
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

variable "enable_aws_ebs_csi_driver_role" {
  description = "Enable AWS EBS CSI driver role"
  type        = bool
  default     = false
}

variable "enable_aws_efs_csi_driver_role" {
  description = "Enable AWS EFS CSI driver role"
  type        = bool
  default     = false
}

variable "enable_aws_lbc_role" {
  description = "Enable AWS Load Balancer Controller role"
  type        = bool
  default     = false
}

variable "enable_cloudwatch_observability_addon" {
  description = "Enable CloudWatch observability addon"
  type        = bool
  default     = false
}

variable "enable_secrets_store_csi_driver_role" {
  description = "Enable Secrets Store CSI driver role"
  type        = bool
  default     = false
}