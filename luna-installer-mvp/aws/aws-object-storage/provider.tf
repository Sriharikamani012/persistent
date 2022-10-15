/*************************************************************************
Provider Initilizations 
*************************************************************************/
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0, < 4.0"
    }
    local      = "~> 1.2"
    null       = "~> 2.1"
    random     = "~> 2.1"
    template   = "~> 2.1"
  }
}

provider "aws" {
  profile = "default"
  region  = var.region
}

terraform {
  required_version = "~>0.13.0"
}
