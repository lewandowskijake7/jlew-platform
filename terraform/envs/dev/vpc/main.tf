### Terraform Configuration
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
    key = "envs/dev/vpc/terraform.tfstate"
    region = "us-east-2"
    encrypt = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-2"
}

### Modules
module "vpc" {
  source = "../../../modules/vpc"

  vpc_name                 = "jlew-dev"
  vpc_cidr_block           = "10.0.0.0/16"
  azs                      = ["us-east-2a", "us-east-2b"]
  public_subnet_cidr_blocks  = ["10.0.0.0/24", "10.0.1.0/24"]
  private_subnet_cidr_blocks = ["10.0.10.0/24", "10.0.11.0/24"]
  tags = { Project = "jlew-platform" }
}


### Outputs
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "vpc_cidr_block" {
  value = module.vpc.vpc_cidr_block
}