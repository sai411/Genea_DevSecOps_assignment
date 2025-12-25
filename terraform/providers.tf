terraform {
  required_version = ">= 1.4.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "user-management-services"
    key          = "terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}
