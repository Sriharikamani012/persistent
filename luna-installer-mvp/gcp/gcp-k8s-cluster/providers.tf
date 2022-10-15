/*************************************************************************
 GCP Providers File
*************************************************************************/
#The cloud platform used
provider "google" {
  credentials = "../../gcp-creds.json"
  project = var.gcp_project_id
  region  = var.region
}

#Terraform verison and creating remote backend. The values get passed in through the backend.tfvars file
terraform {
  required_version = ">=0.13.0"
  required_providers {
    gcp = {
      source  = "hashicorp/google"
      version = "~> 3.44.0"
    }
  }
  backend "gcs" {
  }
}
