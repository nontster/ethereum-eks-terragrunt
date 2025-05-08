variable "aws_region" {
  description = "The AWS region to create the VPC in."
  type        = string  
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string  
}

variable "environment_name" {
  description = "value of the environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "aws_availability_zones" {
  description = "List of availability zones to use for the VPC."
  type        = list(string)
  default     = [] # Default to empty list, will be populated by the module
}

variable "enable_intra_subnets" {
  description = "Set to true to create intra subnets (for internal traffic, often used with Transit Gateway)."
  type        = bool
  default     = false # Default to false as they are not always needed
}

variable "enable_nat_gateway" {
  description = "Set to true to create NAT Gateways for private subnets. Set to false for no NAT Gateways."
  type        = bool
  default     = true
}

variable "enable_vpn_gateway" {
  description = "Set to true to create a VPN Gateway."
  type        = bool
  default     = false
}

variable "single_nat_gateway" {
  description = "Set to true to create a single NAT Gateway. Requires enable_nat_gateway=true."
  type        = bool
  default     = false
}

variable "one_nat_gateway_per_az" {
  description = "Set to true to create a NAT Gateway in each AZ. Requires enable_nat_gateway=true."
  type        = bool
  default     = true # Match underlying module's default if applicable
}

# NEW: Variable to control NAT Gateway strategy
variable "nat_gateway_strategy" {
  description = "Defines the NAT Gateway creation strategy. Allowed values: 'none', 'single', 'per_az', 'per_subnet'."
  type        = string
  default     = "per_subnet" # Defaulting to one NAT GW per subnet

  validation {
    # Ensure the input value is one of the allowed strategies
    condition     = contains(["none", "single", "per_az", "per_subnet"], var.nat_gateway_strategy)
    error_message = "Allowed values for nat_gateway_strategy are: 'none', 'single', 'per_az', 'per_subnet'."
  }
}

variable "tags" {
  description = "A map of tags to assign to the VPC and other resources."
  type        = map(string)
  default     = {}
}

variable "public_subnet_tags" {
  description = "A map of tags to assign specifically to public subnets."
  type        = map(string)
  default = {
    "Type"                       = "Public"
    "kubernetes.io/role/elb"     = "1" # Tag for Kubernetes AWS Load Balancer Controller
  }
}

variable "private_subnet_tags" {
  description = "A map of tags to assign specifically to private subnets."
  type        = map(string)
  default = {
    "Type"                              = "Private"
    "kubernetes.io/role/internal-elb"   = "1" # Tag for Kubernetes AWS Load Balancer Controller
  }
}

variable "intra_subnet_tags" {
  description = "A map of tags to assign specifically to intra subnets (if enabled)."
  type        = map(string)
  default = {
    "Type" = "Intra"
  }
}