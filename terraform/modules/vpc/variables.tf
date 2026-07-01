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