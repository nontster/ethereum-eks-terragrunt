output "vpc_id" {
  description = "The ID of the VPC."
  value       = module.vpc.vpc_id
}

output "vpc_arn" {
  description = "The ARN of the VPC."
  value       = module.vpc.vpc_arn
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC."
  value       = module.vpc.vpc_cidr_block
}
  
output "default_security_group_id" {
  description = "The ID of the default security group."
  value       = module.vpc.default_security_group_id
}

output "default_network_acl_id" {
  description = "The ID of the default network ACL."
  value       = module.vpc.default_network_acl_id
}

output "default_route_table_id" {
  description = "The ID of the default route table."
  value       = module.vpc.default_route_table_id
}

output "vpc_enable_dns_support" {
  description = "Whether DNS support is enabled for the VPC."
  value       = module.vpc.vpc_enable_dns_support
}

output "vpc_enable_dns_hostnames" {
  description = "Whether DNS hostnames are enabled for the VPC."
  value       = module.vpc.vpc_enable_dns_hostnames
}

output "vpc_main_route_table_id" {
  description = "The ID of the main route table."
  value       = module.vpc.vpc_main_route_table_id
}

output "public_subnets" {
  description = "List of IDs of public subnets."
  value       = module.vpc.public_subnets[*] # Use splat expression to handle potential null
}

output "private_subnets" {
  description = "List of IDs of private subnets."
  value       = module.vpc.private_subnets[*] # Use splat expression to handle potential null
}

output "intra_subnets" {
  description = "List of IDs of intra subnets (if enabled)."
  value       = module.vpc.intra_subnets[*] # Use splat expression to handle potential null
}

# NEW: Output for calculated AZs used
output "aws_availability_zones" {
  description = "List of availability zones used for the VPC."
  value       = module.vpc.azs
}