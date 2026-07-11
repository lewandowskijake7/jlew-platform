variable "cluster_name" {
  type        = string
  description = "The name of the EKS cluster"
  # "jlew-dev"
  # Self-defined limit of 30 characters for the cluster name.
  validation {
    condition = (
      length(var.cluster_name) >= 3 &&
      length(var.cluster_name) <= 30 &&
      regexall("^[a-z][-a-z0-9]*$", var.cluster_name) != []
    )
    error_message = "cluster_name must be between 3 and 30 characters long and can only contain lowercase letters, numbers, and hyphens."
  }
}

variable "kubernetes_version" {
  type        = string
  description = "The version of Kubernetes to use for the EKS cluster"
  # "1.31"
  validation {
    condition = (
      can(regex("^[0-9]+\\.[0-9]+$", var.kubernetes_version))
    )
    error_message = "kubernetes_version must be a valid Kubernetes version."
  }
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC to deploy the EKS cluster in"
  # "vpc-01234567890123456"
  validation {
    condition = (
      can(regex("^vpc-[a-f0-9]+$", var.vpc_id))
    )
    error_message = "vpc_id must be a valid VPC ID."
  }
}

variable "cluster_subnet_ids" {
  type        = list(string)
  description = "The IDs of the subnets to deploy the EKS cluster in"
  # ["subnet-01234567890123456", "subnet-01234567890123457", ...]
  validation {
    condition = (
      alltrue([for id in var.cluster_subnet_ids : can(regex("^subnet-[a-f0-9]+$", id))])
    )
    error_message = "cluster_subnet_ids must be a list of valid subnet IDs."
  }
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "The IDs of the private subnets to deploy the EKS cluster in"
  # ["subnet-01234567890123456", "subnet-01234567890123457"]
  validation {
    condition = (
      alltrue([for id in var.private_subnet_ids : can(regex("^subnet-[a-f0-9]+$", id))])
    )
    error_message = "private_subnet_ids must be a list of valid subnet IDs."
  }
}

variable "node_instance_types" {
  type        = list(string)
  description = "The instance types of the nodes to deploy the EKS cluster in"
  # ["t3.medium"]
  default = ["t3.medium"]
  validation {
    condition = (
      length(var.node_instance_types) >= 1 &&
      alltrue([for t in var.node_instance_types : can(regex("^[a-z0-9]+\\.[a-z0-9]+$", t))])
    )
    error_message = "node_instance_types must be a list of at least 1 valid instance types."
  }
}

variable "node_desired_size" {
  type        = number
  description = "The desired size of the nodes to deploy the EKS cluster in"
  # 2
  default = 2
  validation {
    condition = (
      var.node_desired_size >= 1 &&
      var.node_desired_size <= 10
    )
    error_message = "node_desired_size must be between 1 and 10."
  }
}

variable "node_max_size" {
  type        = number
  description = "The maximum size of the nodes to deploy the EKS cluster in"
  # 10
  default = 10
  validation {
    condition = (
      var.node_max_size >= 1 &&
      var.node_max_size <= 10
    )
    error_message = "node_max_size must be between 1 and 10."
  }
}

variable "node_min_size" {
  type        = number
  description = "The minimum size of the nodes to deploy the EKS cluster in"
  # 1
  default = 1
  validation {
    condition = (
      var.node_min_size >= 1 &&
      var.node_min_size <= 10
    )
    error_message = "node_min_size must be between 1 and 10."
  }
}

variable "endpoint_public_access" {
  type        = bool
  description = "Whether to enable public access to the EKS cluster"
  # true
  default = true
}

variable "endpoint_private_access" {
  type        = bool
  description = "Whether to enable private access to the EKS cluster"
  # true
  default = true
}

variable "enable_cluster_log_types" {
  type        = list(string)
  description = "The types of logs to enable for the EKS cluster"
  # ["api", "audit"]
  default = ["api", "audit"]
  validation {
    condition = (
      length(var.enable_cluster_log_types) == 0 ||
      alltrue([
        for t in var.enable_cluster_log_types :
        contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], t)
      ])
    )
    error_message = "Each log type must be one of: api, audit, authenticator, controllerManager, scheduler."
  }
}

variable "tags" {
  type        = map(string)
  description = "The tags to add to the EKS cluster"
  # {
  #   "Name" = "jlew-dev"
  #   "Environment" = "dev"
  #   "Owner" = "jlew"
  # }
  default = {}
}