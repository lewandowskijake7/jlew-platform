variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
  # "jlew-platform"
  validation {
    condition     = length(var.vpc_name) > 0
    error_message = "name must be a non-empty string."
  }
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block for the VPC"
  # "10.0.0.0/16"
  validation {
    condition = (
      tonumber(split("/", var.vpc_cidr_block)[1]) >= 16 &&
      tonumber(split("/", var.vpc_cidr_block)[1]) <= 28
    )
    error_message = "vpc_cidr_block must be between /16 and /28 (AWS VPC limits)."
  }
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones to deploy the subnets in"
  # ["us-east-2a", "us-east-2b"]
  validation {
    condition     = length(var.azs) >= 2
    error_message = "Use at least 2 AZs for high availability."
  }
}

variable "public_subnet_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks for the public subnets"
  # ["10.0.0.0/24", "10.0.1.0/24"]
  validation {
    condition     = length(var.public_subnet_cidr_blocks) == length(var.azs)
    error_message = "public_subnet_cidr_blocks must have exactly one CIDR per AZ in var.azs."
  }
}

variable "private_subnet_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks for the private subnets"
  # ["10.0.10.0/24", "10.0.11.0/24"]
  validation {
    condition     = length(var.private_subnet_cidr_blocks) == length(var.azs)
    error_message = "private_subnet_cidr_blocks must have exactly one CIDR per AZ in var.azs."
  }
}

variable "enable_dns_hostnames" {
  type        = bool
  description = "Enable DNS hostnames for the VPC"
  # true
  default = true
}

variable "enable_dns_support" {
  type        = bool
  description = "Enable DNS support for the VPC"
  # true
  default = true
}

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
  # { "Project" = "jlew-platform" }
  default = {}
}