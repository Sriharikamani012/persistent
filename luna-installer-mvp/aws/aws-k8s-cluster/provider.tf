/*************************************************************************
Provider Initilizations 
*************************************************************************/
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
    local      = "~> 1.2"
    null       = "~> 2.1"
    random     = "~> 2.1"
    template   = "~> 2.1"
  }
}

provider "aws" {
  profile = "default"
  region  = var.region #ToDo Change this to a parameter
}

terraform {
  backend "s3" {
    encrypt = true
  }
}

terraform {
  required_version = "~>0.13.0"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
  version                = "~> 1.11"
}
