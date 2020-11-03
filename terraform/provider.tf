terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }

  # needs to be manually created
  backend "s3" {
    bucket = "aaas-terraform-state"
    key    = "state/cloudmapper-scanner"
    region = "eu-west-1"
  }
}

provider "aws" {
  region = "eu-west-1"
}
