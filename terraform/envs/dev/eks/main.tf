terraform {
  required_version = ">= 1.15.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.51"
    }
  }

  backend "s3" {
    bucket = "jlew-platform-state"
    key = "envs/dev/eks/terraform.tfstate"
    region = "us-east-2"
    encrypt = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-2"
}

data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "jlew-platform-state"
    key    = "envs/dev/vpc/terraform.tfstate"
    region = "us-east-2"
  }
}

module "eks" {
  source = "../../../modules/eks"

  cluster_name       = "jlew-dev"
  kubernetes_version = "1.31"
  vpc_id             = data.terraform_remote_state.vpc.outputs.vpc_id
  cluster_subnet_ids = concat(
    values(data.terraform_remote_state.vpc.outputs.public_subnet_ids),
    values(data.terraform_remote_state.vpc.outputs.private_subnet_ids),
  )
  private_subnet_ids = values(data.terraform_remote_state.vpc.outputs.private_subnet_ids)
  tags               = { Project = "jlew-platform" }
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}